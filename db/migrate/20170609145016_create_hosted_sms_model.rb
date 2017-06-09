class CreateHostedSmsModel < ActiveRecord::Migration
  def change
    create_table :hosted_sms do |t|
      t.string :phone_number, index: true
      t.string :account_sid, index: true
      t.string :address_sid
      t.string :email, index: true
      t.string :friendly_name
      t.string :incoming_phone_number_sid, index: true
      t.string :sid, index: true
      t.string :signing_document_sid, index: true
      t.string :status
      t.string :unique_name
      t.string :url
      t.timestamps null: false
    end
  end
end
