class AddAvatarToImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.attachment :avatar

      t.timestamps
    end
  end
end