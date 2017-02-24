class AddEmailColumnOnStripeCred < ActiveRecord::Migration
  def change
    add_column :stripe_creds, :email, :string, after: 'id'
  end
end
