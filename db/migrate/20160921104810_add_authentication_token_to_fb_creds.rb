class AddAuthenticationTokenToFbCreds < ActiveRecord::Migration
  def change
    add_column :fb_creds, :auth_token, :string
  end
end
