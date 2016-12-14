class AddUniquenessForCampaignName < ActiveRecord::Migration
  def up
    add_index :campaigns, :name, unique: true
  end
  def down
    remove_index :campaigns, :name
  end
end
