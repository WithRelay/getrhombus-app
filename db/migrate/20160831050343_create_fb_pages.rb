class CreateFbPages < ActiveRecord::Migration
  def change
    create_table :fb_pages do |t|
      t.string :page_id
      t.integer :user_id
      t.string :category
      t.string :page_access_token

      t.timestamps null: false
    end
  end
end
