class CreateApiCredModel < ActiveRecord::Migration
  def change
    create_table :api_creds do |t|
      t.string :api_key, index: true
      t.string :api_secret, index: true
      t.integer :user_id
    end
  end
end
