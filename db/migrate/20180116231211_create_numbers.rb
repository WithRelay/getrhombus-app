class CreateNumbers < ActiveRecord::Migration
  def change
    create_table :numbers do |t|
      t.references :user, index: true
      t.string :number, unique: true, index: true
      t.string :friendly_name
      t.string :provider, default: 'twilio'
      t.string :fibernetics_subscriber_id
      t.string :type
      t.string :country
      t.integer :price, default: 100
      t.boolean :default, default: false

      t.timestamps null: false
    end
  end
end
