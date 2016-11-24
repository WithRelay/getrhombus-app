# class for adding column account_id in stripe_creds table
class AddColumnAccountIdToStripCreds < ActiveRecord::Migration

  # for rake task db:migrate the up method is called and add column as mention
  def up
    add_column :stripe_creds, :account_id, :string
  end

  # for rake db:rollback down method will be called and remove column
  def down
    remove_column :stripe_creds, :account_id, :string
  end
end
