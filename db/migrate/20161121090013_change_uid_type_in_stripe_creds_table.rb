class ChangeUidTypeInStripeCredsTable < ActiveRecord::Migration
  def up
    change_column :stripe_creds, :uid_type, :integer
  end

  def down
    change_column :stripe_creds, :uid_type, :string
  end
end
