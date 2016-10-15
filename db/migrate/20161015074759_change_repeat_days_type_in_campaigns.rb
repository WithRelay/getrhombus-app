class ChangeRepeatDaysTypeInCampaigns < ActiveRecord::Migration
  def change
    change_column :campaigns, :repeat_days, :integer
    rename_column :campaigns, :delivery_type, :deliver_now
  end
end
