# table creating for campaign which is associated with merchant
class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.integer :channel
      t.integer :status, default: 1
      t.timestamps null: false
      t.references :user
    end
    add_index :campaigns, [:id, :user_id]
  end
end
