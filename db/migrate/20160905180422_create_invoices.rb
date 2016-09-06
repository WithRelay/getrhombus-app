class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|

      t.integer :date

      t.string :stripe_invoice_id, index: true
      t.references :user
      t.references :team
      t.references :coupon
      t.references :subscription
      t.references :transaction       
      
      t.integer :total
      t.integer :subtotal
      t.integer :tax
      t.string :tax_percent             # when we open up invoicing, merchant should be able to set this per invoice
      t.integer :application_fee
      t.integer :amount_due
      t.string :currency                # when we open up invoicing, merchant should be able to set this per invoice

      t.integer :starting_balance
      t.integer :ending_balance
      t.integer :period_start
      t.integer :period_end
      t.string :statement_descriptor    # when we open up invoicing, merchant should be able to set this per invoice

      t.boolean :paid
      t.boolean :closed
      t.boolean :attempted
      t.integer :attempt_count
      t.integer :next_payment_attempt
      t.boolean :forgiven
      t.boolean :livemode

    end


    change_column :subscriptions, :tax_percent, :string
    change_column :users, :customer_uri, :string, index: true
    rename_column :transactions, :rhombus_fee, :application_fee
    add_foreign_key :invoices, :users
    add_foreign_key :invoices, :users, column: :team_id  
    add_foreign_key :invoices, :coupons
    add_foreign_key :invoices, :subscriptions
    add_foreign_key :invoices, :transactions
  end
end
