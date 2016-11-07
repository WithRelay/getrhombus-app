class CreateMessageResolutions < ActiveRecord::Migration
  def change
    create_table :message_resolutions do |t|
      t.string :title
      t.references :user

	  t.timestamps null: false
    end

    add_foreign_key :message_resolutions, :users
  end
end
