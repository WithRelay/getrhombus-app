class UpdateIndexInNumbersTable < ActiveRecord::Migration
  def change
    add_index :numbers, [:user_id, :number]
  end
end
