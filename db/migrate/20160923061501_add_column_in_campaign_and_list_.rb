# migration for adding column in campaign and list as below
class AddColumnInCampaignAndList < ActiveRecord::Migration
  def change
    add_column :campaigns, :delivery_type, :string
    add_column :campaigns, :repeat_days, :string
    add_column :campaigns, :frequency_type, :integer
    add_column :campaigns, :date, :datetime
    add_column :campaigns, :time, :datetime
  end
end
