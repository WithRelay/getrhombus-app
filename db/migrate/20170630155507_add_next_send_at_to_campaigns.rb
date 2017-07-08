class AddNextSendAtToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :next_send_at, :timestamp, after: :date_time
  end
end
