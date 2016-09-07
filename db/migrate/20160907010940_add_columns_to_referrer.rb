class AddColumnsToReferrer < ActiveRecord::Migration
  def change
    add_column :referrers, :ip, :string, after: :country
    add_column :referrers, :city, :string, after: :country
    add_column :referrers, :region, :string, after: :country
    add_column :referrers, :postal, :string, after: :country
  end
end
