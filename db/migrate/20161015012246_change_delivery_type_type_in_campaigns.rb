class ChangeDeliveryTypeTypeInCampaigns < ActiveRecord::Migration
  def change
  	change_column :campaigns, :delivery_type, :boolean
  end
end
