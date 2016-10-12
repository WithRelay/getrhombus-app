class ConvertSavedRepliesToUtf8mb4 < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE saved_replies CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin"
  end

  def down
    execute "ALTER TABLE saved_replies CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;"
  end
end
