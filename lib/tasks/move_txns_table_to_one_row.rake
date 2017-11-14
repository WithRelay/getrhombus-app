
# TASK 12. Tested

# run after migrations to create/rename the columns, since table need to be redone first
# then run the migration below to remove the unwanted columns afterwards.

#  def change
#    remove_column :transactions, :referenced_customer_transaction_id
#    remove_column :transactions, :referenced_merchant_transaction_id
#    remove_column :transactions, :referenced_user_id
#    remove_column :transactions, :transaction_type
#    remove_column :transactions, :amount_less_fees
#  end


# we currently store a single payment across three rows
# move to using one row but data needs to be moved

# run this check for cleanup
=begin
  # ensures each platform transaction has a merchant and customer transaction
  select * from transactions where transaction_type = 0 
  and referenced_customer_transaction_id is null  # = '' # done

  select * from transactions where transaction_type = 0 
  and referenced_merchant_transaction_id = '' # is null   # done

  # ensure platform txn has amount_less_fees and amount
  select * from transactions where transaction_type = 0
  and amount_less_fees is null                             # done

  # make sure customer transaction references a merchant
  select * from transactions where transaction_type = 1
  and team_id = '' # is null                                # done

  there should be 3x 
  select count(*) from transactions where transaction_type = 0  # done but number doesnt add up

  select * from transactions where transaction_type = 1 and id not in
  (select referenced_customer_transaction_id from transactions where transaction_type = 0)

  #133, 134, 135, 136, 800, 801, 802, 803, 804, 805, 25604 customer txns with no matching platform txns
  #73, 81, 87, 89, 25611 merchant txns with no matching platform txns
=end

desc "Refactor table to use only one row"
task :move_txns_table_to_one_row => :environment do

  def app_fee(amt, rate); Toolbox::Decimal.to_cents((amt - amt_less_fees(amt, rate)) - stripe_fee(amt)) end
  def amt_less_fees(amt, rate); (((1 - rate) * amt) - 0.3) end
  def stripe_fee(amt); ((0.029 * amt) + 0.3) end

#=begin
  Transaction.where(transaction_type: 1).each do |t|
    unless Transaction.find_by(transaction_type: 0, txn_uri: t.txn_uri)
      puts "#{t.id} has no platform transaction"
    end
  end

  ActiveRecord::Base.transaction do
    # customer txns
    Transaction.where(id: [133, 134, 135, 136, 800, 801, 802, 803, 804, 805]).each do |t|
      t.app_fee = app_fee(t.amount_with_taxes, 0.035)
      t.stripe_fee = Toolbox::Decimal.to_cents(stripe_fee(t.amount_with_taxes))
      t.save!
    end

    Transaction.where(id: [25604]).each do |t|
      t.app_fee = app_fee(t.amount_with_taxes, 0.029)
      t.stripe_fee = Toolbox::Decimal.to_cents(stripe_fee(t.amount_with_taxes))
      t.save!
    end

    # matching merchant transaction for txn above
    Transaction.where(id: [25611]).delete_all

    # merchant txns
    Transaction.where(id: [73, 81, 87, 89]).each do |t|
      txn = Transaction.find_by(txn_uri: t.txn_uri, transaction_type: 0)
      txn.amount_less_fees = amt_less_fees(t.amount_with_taxes, 0.035)
      txn.referenced_merchant_transaction_id = t.id
      txn.save!

      txn = Transaction.find_by(txn_uri: t.txn_uri, transaction_type: 1)
      txn.referenced_merchant_transaction_id = t.id
      txn.save!
    end
  end
#=end

  platform_txns = Transaction.where(transaction_type: 0)
  
  ActiveRecord::Base.transaction do
    platform_txns.each do |t|
      puts "\n"
      puts "platform transaction id #{t.id}"

      # update user transaction
      Transaction.where(id: t.referenced_customer_transaction_id).each do |c|
        puts "customer transaction id #{c.id}"
        c.update!(app_fee: Toolbox::Decimal.to_cents(t.amount), 
                  stripe_fee: Toolbox::Decimal.to_cents(t.amount_with_taxes - t.amount_less_fees - t.amount))
      end

      # delete merchant transaction
      Transaction.where(id: t.referenced_merchant_transaction_id).delete_all
    end

    # delete all platform txns
    platform_txns.delete_all
  end

end

### NOTE the fee change....also recalculate the rate_percent
### Now use transaction fee table to store fees

# 390 was right
 
# (((1 − 0.035) * amount_with_taxes) − .3) # amount_less_fees

# (((0.029 * amount_with_taxes) + .3) # stripe fee

# ( (amount_with_taxes - amount_less_fees) − .3) −  (0.029 × amount_with_taxes)  # app fee

# (amount_with_taxes - amount_less_fees) - stripe_fee = app_fee

# 4.215 - 4.22 (round up/down)  45.525
# .815 - .81 (round down)   32.775


# NOTES
# After running rake task, we still have some early transactions have incorrect stripe fees. We might update this in the future
