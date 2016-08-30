class AddOrganizationTypeToUsers < ActiveRecord::Migration
  def change
    rename_column :users, :business_type, :org_category
    rename_column :users, :business_name, :org_name
    rename_column :users, :business_phone, :org_phone
    add_column :users, :org_type, :string, after: :org_name, default: nil
  end
end
