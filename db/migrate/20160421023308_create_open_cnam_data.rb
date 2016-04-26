class CreateOpenCnamData < ActiveRecord::Migration
  def change
    create_table :open_cnam_data do |t|
      t.string :name
      t.string :phone_number
      t.string :price

      t.timestamps
    end

    add_index :open_cnam_data, :phone_number, unique: true
  end
end
