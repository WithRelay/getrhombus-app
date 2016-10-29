
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
  and referenced_merchant_id = ''
=end

desc "Refactor table to use only one row"
task :move_txns_table_to_one_row => :environment do

  platform_txns = Transaction.where(transaction_type: 0)
  
  platform_txns.each do |t|

    # update user transaction
    Transaction.where(id: t.referenced_customer_transaction_id).each do |c|
      c.rhombus_fee = t.amount
      c.amount_less_fees = t.amount_less_fees
      c.save
    end

    # delete merchant transaction
    Transaction.where(id: t.referenced_merchant_transaction_id).delete_all
  end

  # delete all platform txns
  platform_txns.delete_all
end