class RemoveColumnTimeDeliveryTypeInCampaign < ActiveRecord::Migration
  def change
    # rename_column :campaigns, :date, :date_time
    # remove_column :campaigns, :time, :datetime
    # add_column :campaigns, :delivery_type, :string
    change_column :campaigns, :frequency_type, :string
  end
end
