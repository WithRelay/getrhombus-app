class CreateReferrers < ActiveRecord::Migration
  def change
    create_table :referrers do |t|
      t.string :referrer_email, index: true
      t.string :email, index: true
      t.string :phone_number
      t.integer :referrer_id, index: true
      t.integer :referee_id, index: true
      t.string :country
      t.string :link, index: true
      t.string :referrer_name
      t.string :business_name
      t.string :uid, index: true

      t.timestamps null: false
    end
  end
end
