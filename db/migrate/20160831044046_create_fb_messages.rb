class CreateFbMessages < ActiveRecord::Migration
  def change
    create_table :fb_messages do |t|
      t.text :text
      t.integer :time_stamp
      t.boolean :unread
      t.integer :message_id
      t.integer :transaction_id
      t.integer :page_id
      t.string :from
      t.string :to

      t.timestamps null: false
    end
    add_index :fb_messages, :from
    add_index :fb_messages, :to
  end
end
