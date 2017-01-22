class CreateDemos < ActiveRecord::Migration
  def change
    create_table :demos do |t|
      t.string :full_name
      t.string :company
      t.string :email
      t.string :phone
      t.string :employee_count

      t.timestamps null: false
    end
  end
end
