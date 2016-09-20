class ModifyColumnsInUsers < ActiveRecord::Migration
  def change
    rename_column :users, :rhombus_number_type, :rn_type
    rename_column :users, :instrument_uri, :card_token
    change_column :users, :card_token, :string, after: :customer_uri
    add_column :users, :rn_country, :string, after: :rn_type
    add_column :users, :description, :text, after: :country
    add_column :users, :use_rhombus_for, :string, after: :description
    add_column :users, :org_tax_id, :string, after: :org_category
    change_column :users, :org_phone, :string, after: :org_category
    change_column :users, :stripe_livemode, :string, after: :card_token
    rename_column :users, :stripe_livemode, :livemode
    rename_column :users, :last_four, :last4
    rename_column :transactions, :last_four, :last4
    rename_column :users, :expiration_month, :exp_month
    rename_column :users, :expiration_year, :exp_year
  end
end
