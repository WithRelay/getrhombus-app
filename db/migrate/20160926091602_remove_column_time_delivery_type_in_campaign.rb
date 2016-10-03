class RemoveColumnTimeDeliveryTypeInCampaign < ActiveRecord::Migration
  def change
    rename_column :campaigns, :date, :date_time
    remove_column :campaigns, :time, :datetime
    change_column :campaigns, :frequency_type, :string
  end
end
