class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.integer :user_id
      t.text :text
      t.string :rule_type
      t.integer :message_length

      t.timestamps null: false
    end

    add_index :rules, :user_id
  end
end
