class AddIndexesToFromAndToInMessages < ActiveRecord::Migration
  def change
  	add_index :messages, :from
  	add_index :messages, :to
  end
end
