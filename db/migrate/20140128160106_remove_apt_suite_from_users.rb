class RemoveAptSuiteFromUsers < ActiveRecord::Migration
  def change
  	remove_column :users, :apt_suite
  end
end
