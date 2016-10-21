# table for storing campaign recipient
# the up methods creates table and the down drop the table
class CreateCampaignUserLists < ActiveRecord::Migration
  def change
    create_table :campaign_user_lists do |t|
      t.references :user
      t.references :campaign
      t.timestamps null: false
    end
    add_index :campaign_user_lists, [ :id, :user_id, :campaign_id ]
    add_foreign_key :campaign_user_lists, :campaigns
    add_foreign_key :campaign_user_lists, :users
  end

  def down
    drop_table :campaign_user_lists do |t|
      t.references :user
      t.references :campaign
      t.timestamps null: false
    end
    remove_index :campaign_user_lists, [ :id, :user_id, :campaign_id ]
    add_foreign_key :campaign_user_lists, :campaigns
    add_foreign_key :campaign_user_lists, :users
  end
end
