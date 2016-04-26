class CreateTwitterCred < ActiveRecord::Migration
  def change
    create_table :twitter_creds do |t|
      t.string :nickname, default: nil
      t.string :name, default: nil
      t.string :location, default: nil
      t.string :image_url, default: nil
      t.string :description, default: nil
      t.string :website_url, default: nil
      t.string :url, default: nil
      t.integer :followers_count, default: 0
      t.integer :friends_count, default: 0
      t.string :uid, default: nil
      t.string :token, default: nil
      t.string :secret, default: nil
      t.integer :user_id, index: { unique: true }
    end
  end
end
