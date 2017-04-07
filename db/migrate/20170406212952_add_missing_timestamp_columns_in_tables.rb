class AddMissingTimestampColumnsInTables < ActiveRecord::Migration
  def change
    add_column(:twitter_creds, :created_at, :datetime, null: false) unless column_exists? :twitter_creds, :created_at
    add_column(:twitter_creds, :updated_at, :datetime, null: false) unless column_exists? :twitter_creds, :updated_at

    add_column(:merchant_customers, :created_at, :datetime, null: false) unless column_exists? :merchant_customers, :created_at
    add_column(:merchant_customers, :updated_at, :datetime, null: false) unless column_exists? :merchant_customers, :updated_at

    add_column(:invoices, :created_at, :datetime, null: false) unless column_exists? :invoices, :created_at
    add_column(:invoices, :updated_at, :datetime, null: false) unless column_exists? :invoices, :updated_at
  end
end
