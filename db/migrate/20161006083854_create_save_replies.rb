class CreateSaveReplies < ActiveRecord::Migration
  def change
    create_table :save_replies do |t|
      t.string :title
      t.text :body

      t.timestamps null: false
    end
    add_reference :save_replies, :user, index: true
    add_foreign_key :save_replies, :users
  end
end
