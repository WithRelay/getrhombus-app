class RemoveClientRefFromMessages < ActiveRecord::Migration
  def change
  	remove_column :messages, :client_ref
  end
end
