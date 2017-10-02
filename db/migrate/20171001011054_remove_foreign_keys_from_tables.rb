class RemoveForeignKeysFromTables < ActiveRecord::Migration
  def change
    remove_foreign_key "coupons", "users"
    remove_foreign_key "hashtags", "users"
    remove_foreign_key "lists", "users"
    remove_foreign_key "message_resolutions", "users"
    remove_foreign_key "messages", "hashtags"
    remove_foreign_key "refunds", "transactions"
    remove_foreign_key "transactions", "hashtags"
    remove_foreign_key "transactions", "subscriptions"
  end
end
