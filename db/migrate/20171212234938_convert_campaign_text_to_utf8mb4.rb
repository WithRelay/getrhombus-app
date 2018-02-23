class ConvertCampaignTextToUtf8mb4 < ActiveRecord::Migration
  def change
    execute "ALTER TABLE campaigns CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
    execute "ALTER TABLE campaigns MODIFY text TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end
end
