class AddRelayUidToUsers < ActiveRecord::Migration
  def change
    add_column :users, :relay_uid, :string
    add_index :users, :relay_uid, unique: true
    remove_column :referrers, :referrer_id
    remove_column :referrers, :uid
    add_column :referrers, :referrer_uid, :string, index: true, after: :phone_number
  end
end
