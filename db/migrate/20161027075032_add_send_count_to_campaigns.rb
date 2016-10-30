class AddSendCountToCampaigns < ActiveRecord::Migration
  def up
    add_column :campaigns, :send_count, :integer, default: 0
  end

  def down
    remove_column :campaigns, :send_count, :integer, default: 0
  end
end
