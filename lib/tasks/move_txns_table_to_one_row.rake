
# run after migrations to create/rename the columns, since table need to be redone first
# then run the migration below to remove the unwanted columns afterwards.

#  def change
#    remove_column :transactions, :referenced_customer_transaction_id
#    remove_column :transactions, :referenced_merchant_transaction_id
#    remove_column :transactions, :referenced_user_id
#    remove_column :transactions, :transaction_type
#  end


# we currently store a single payment across three rows
# move to using one row
# but data needs to be moved

# run this check for cleanup
=begin
  # ensures each platform transaction has a merchant and customer transaction
  select * from transactions where transaction_type = 0 
  and referenced_customer_transaction_id is null  # = ''

  select * from transactions where transaction_type = 0 
  and referenced_merchant_transaction_id = '' # is null

  # ensure platform txn has amount_less_fees and amount
  select * from transactions where transaction_type = 0
  and amount_less_fees is null

  # make sure customer transaction references a merchant
  select * from transactions where transaction_type = 1
  and referenced_merchant_id = '' # is null

  there should be 3x 
  select count(*) from transactions where transaction_type = 0

  select * from transactions where transaction_type = 1 and id not in
(select referenced_customer_transaction_id from transactions where transaction_type = 0)
=end

desc "Refactor table to use only one row"
task :move_txns_table_to_one_row => :environment do

  platform_txns = Transaction.where(transaction_type: 0)
  
  platform_txns.each do |t|

    # update user transaction
    Transaction.where(id: t.referenced_customer_transaction_id).each do |c|
      c.application_fee = t.amount
      c.amount_less_fees = t.amount_less_fees
      c.save
    end

    # delete merchant transaction
    Transaction.where(id: t.referenced_merchant_transaction_id).delete_all
  end

  # delete all platform txns
  platform_txns.delete_all
end

# split amount_less_fess into amount_less_stripe_fees, app_fee
# then remove amount_less_fees

#amount_with_taxes
# stripe_fee, app_fee = amount_less_fees

# 390 was right
 
# (((1 − 0.035) * amount_with_taxes) − .3) # amount_less_fees

# (((0.029 * amount_with_taxes) + .3) # stripe fee

# ( (amount_with_taxes - amount_less_fees) − .3) −  (0.029 × amount_with_taxes)  # app fee

# (amount_with_taxes - amount_less_fees) - stripe_fee = app_fee

# 4.215 - 4.22 (round up/down)  45.525
# .815 - .81 (round down)   32.775