class CreateTwilioNumberData < ActiveRecord::Migration
  def change
    create_table :twilio_number_data do |t|

      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :phone_number

      t.timestamps
    end

    add_index :twilio_number_data, :phone_number, unique: true
  end
end
