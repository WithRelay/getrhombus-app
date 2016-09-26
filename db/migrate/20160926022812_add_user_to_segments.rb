class AddUserToSegments < ActiveRecord::Migration
  def change
    add_reference :segments, :user, index: true
    add_foreign_key :segments, :users
  end
end
