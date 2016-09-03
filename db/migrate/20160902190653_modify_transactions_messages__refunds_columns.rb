class ModifyTransactionsMessagesRefundsColumns < ActiveRecord::Migration
  def change
    
    change_column :transactions, :amount_with_taxes, :decimal, :precision => 8, :scale => 2, after: :amount_less_fees 
    
    add_column :transactions, :rhombus_fee, :decimal, precision: 8, scale: 2, after: :amount_with_taxes
    
    rename_column :transactions, :referenced_merchant_id, :team_id
    change_column :transactions, :team_id, :integer, index: true  
    add_foreign_key :transactions, :users, column: :team_id  

    remove_column :transactions, :refund_id

    add_reference :transactions, :hashtag, index: true
    add_foreign_key :transactions, :hashtags


    add_reference :transactions, :subscription, index: true
    add_foreign_key :transactions, :subscriptions    

    rename_column :transactions, :tax_rate, :tax_percent
    
    remove_column :transactions, :from   # redundant column
    
    remove_column :transactions, :to    # redundant column
    
    add_reference :messages, :hashtag, index: true
    add_foreign_key :messages, :hashtags
    
    add_reference :refunds, :transaction, index: true
    add_foreign_key :refunds, :transactions


    remove_column :transactions, :account_number
    remove_column :transactions, :account_type
    remove_column :transactions, :account_name

    remove_column :transactions, :routing_number
    remove_column :transactions, :zip_code
    add_column :transactions, :captured, :boolean, default: true

  end
end
