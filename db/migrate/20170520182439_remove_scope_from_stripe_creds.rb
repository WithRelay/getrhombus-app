class RemoveScopeFromStripeCreds < ActiveRecord::Migration
  def change
    remove_column :stripe_creds, :scope
    remove_column :stripe_creds, :refresh_token
  end
end
