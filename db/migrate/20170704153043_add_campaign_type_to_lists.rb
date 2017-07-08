class AddCampaignTypeToLists < ActiveRecord::Migration
  def change
    add_column :lists, :campaign_type, :integer
    remove_column :campaign_lists, :reminder_id
    remove_column :campaign_lists, :merchant_customer_id
    remove_column :campaign_lists, :merchant_contact_id
  end
end
