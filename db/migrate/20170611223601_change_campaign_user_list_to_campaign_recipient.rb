class ChangeCampaignUserListToCampaignRecipient < ActiveRecord::Migration
  def change
    remove_index :campaign_user_lists, column: :campaign_id
    rename_table :campaign_user_lists, :campaign_recipients
    remove_column :campaign_recipients, :user_id
    add_index :campaign_recipients, :campaign_id
    add_column :campaign_recipients, :list_id, :integer, index: true, after: :campaign_id
    add_column :campaign_recipients, :customer_contact_type, :string, after: :list_id
    add_column :campaign_recipients, :customer_contact_id, :integer, after: :customer_contact_type
    add_column :campaign_recipients, :sent_count, :integer, after: :customer_contact_id
  end
end
