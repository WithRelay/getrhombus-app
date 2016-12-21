class DefaultNameInCampaignsToNil < ActiveRecord::Migration
  def change
	change_column :campaigns, :name, :string, default: nil
  end
end
