class RenameColumnsInApiCreds < ActiveRecord::Migration
  def change
    remove_index :api_creds, name: :index_api_creds_on_api_secret
    remove_index :api_creds, name: :index_api_creds_on_api_key

    #rename_column :api_creds, :api_secret, :secret
    rename_column :api_creds, :api_key, :key

    add_index(:api_creds, :key, unique: true)
    add_index(:api_creds, :secret, unique: true)

    add_index(:api_creds, [:key, :secret])
  end
end
