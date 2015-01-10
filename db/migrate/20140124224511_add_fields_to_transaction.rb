class AddFieldsToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :transaction_uri, :string
    add_column :transactions, :transaction_type, :integer   # Debit(1), credit(2), refund(3), reversal(4)

    add_column :transactions, :amount, :decimal
    add_column :transactions, :amount_less_fees, :decimal
    add_column :transactions, :transaction_number, :string
    add_column :transactions, :description, :string
    add_column :transactions, :from, :string
    add_column :transactions, :to, :string
    add_column :transactions, :status, :string
    add_column :transactions, :transaction_available_at, :string

    add_column :transactions, :last_four, :string
    add_column :transactions, :expiration_month, :string
    add_column :transactions, :expiration_year, :string
    add_column :transactions, :zip_code, :string
    add_column :transactions, :card_type, :string
    add_column :transactions, :card_name, :string
    add_column :transactions, :appear_on_statement_as, :string

    add_column :transactions, :tax_rate, :string    
    add_column :transactions, :on_behalf_of_uri, :string
    add_column :transactions, :account_number, :string
    add_column :transactions, :account_type, :string
    add_column :transactions, :account_name, :string
    add_column :transactions, :routing_number, :string
           
    add_column :transactions, :referenced_user_id, :integer
    add_column :transactions, :referenced_transaction_id, :string           

    add_column :transactions, :receipt_sent_at, :string
    add_column :transactions, :refund_reason, :string

    add_reference :transactions, :user, index: true
  end
end
