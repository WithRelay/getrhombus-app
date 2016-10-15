class ChangeFrequencyTypeTypeInCampaigns < ActiveRecord::Migration
  def change
  	change_column :campaigns, :frequency_type, :integer
  	add_column :campaigns, :name, :string, index: true, after: :id
  end
end
