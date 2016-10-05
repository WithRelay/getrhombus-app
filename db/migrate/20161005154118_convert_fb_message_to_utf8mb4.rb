class ConvertFbMessageToUtf8mb4 < ActiveRecord::Migration
  def change
    execute "ALTER TABLE fb_messages CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
    execute "ALTER TABLE fb_messages MODIFY text VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end
end
