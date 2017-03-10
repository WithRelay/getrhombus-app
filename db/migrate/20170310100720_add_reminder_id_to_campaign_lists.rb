class AddReminderIdToCampaignLists < ActiveRecord::Migration
  def change
    add_column :campaign_lists, :reminder_id, :integer
  end
end
