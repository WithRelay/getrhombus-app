class ChangeBodyToUtf8mb4 < ActiveRecord::Migration
  def change
    execute "ALTER TABLE save_replies MODIFY body VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end
end
