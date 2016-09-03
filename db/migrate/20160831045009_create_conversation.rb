class CreateConversation < ActiveRecord::Migration
  def change
    create_table :conversations do |t|
      t.integer :merchant_id
    end
  end
end
