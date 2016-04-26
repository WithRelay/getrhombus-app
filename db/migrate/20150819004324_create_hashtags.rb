class CreateHashtags < ActiveRecord::Migration
  def change
    create_table :hashtags do |t|
      t.string :name
      t.decimal :amount, :precision => 8, :scale => 2
      t.text :response
      t.string :tag
      t.boolean :isPrecedent, default: false
      t.references :user


      t.timestamps null: false
    end
  end
end
