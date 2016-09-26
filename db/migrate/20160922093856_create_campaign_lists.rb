# join table for list and campaign
class CreateCampaignLists < ActiveRecord::Migration
  def change
    create_table :campaign_lists do |t|
      t.references :campaign
      t.references :list
      t.timestamps null: false
    end
    add_index :campaign_lists, [:list_id, :campaign_id]
    add_foreign_key :campaign_lists, :campaigns, column: :campaign_id
    add_foreign_key :campaign_lists, :lists, column: :list_id
  end
end
