class ChangeUidTypeInStripeCred < ActiveRecord::Migration
  def change
  	change_column :stripe_creds, :uid_type, :string
  end
end
