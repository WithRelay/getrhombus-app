class AddCustomerIdToCampaignLists < ActiveRecord::Migration
  def change
    add_column :campaign_lists, :customer_id, :integer
  end
end
