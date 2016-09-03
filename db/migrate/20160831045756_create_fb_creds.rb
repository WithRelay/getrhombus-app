class CreateFbCreds < ActiveRecord::Migration
  def change
    create_table :fb_creds do |t|
      t.string :email
      t.string :name
      t.string :image_url
      t.string :u_id

      t.timestamps null: false
    end
  end
end
