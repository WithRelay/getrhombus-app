class AddSubjectFieldToCampaigns < ActiveRecord::Migration
  def up
    add_column :campaigns, :subject, :text
  end
  def remove
    remove_column :campaigns, :subject, :text
  end
end
