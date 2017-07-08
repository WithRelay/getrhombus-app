class RenameSendCountToSentCountInCampaigns < ActiveRecord::Migration
  def change
    rename_column :campaigns, :send_count, :sent_count
  end
end
