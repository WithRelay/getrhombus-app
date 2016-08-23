class CreateJoinTableListUser < ActiveRecord::Migration
  def change
    create_join_table :lists, :users do |t|
      # t.index [:list_id, :user_id]
      # t.index [:user_id, :list_id]
    end
  end
end
