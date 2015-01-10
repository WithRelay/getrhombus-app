class AddInstrumentUriToUsers < ActiveRecord::Migration
  def change
    add_column :users, :instrument_uri, :string
    add_column :users, :business_zip_code, :string
  end
end
