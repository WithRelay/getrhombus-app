class AddSmsPriceToUsers < ActiveRecord::Migration
  def change
    create_table :sms_fees do |t|
      t.string :provider
      t.decimal :inbound_sms, precision: 16, scale: 8, default: 0.015
      t.decimal :outbound_sms, precision: 16, scale: 8, default: 0.015
      t.decimal :inbound_mms, precision: 16, scale: 8, default: 0.04
      t.decimal :outbound_mms, precision: 16, scale: 8, default: 0.02

      t.timestamps null: false
    end

    add_column :users, :sms_fee_id, :integer, after: :use_rhombus_for, default: 1
  end
end
