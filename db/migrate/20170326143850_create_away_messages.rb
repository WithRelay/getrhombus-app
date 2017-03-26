class CreateAwayMessages < ActiveRecord::Migration

  WEEK_CT_VALUE = '5:00 PM'; WEEK_OT_VALUE = '9:00 AM'

  private_constant :WEEK_CT_VALUE, :WEEK_OT_VALUE

  def change
    create_table :away_messages do |t|
      t.integer :user_id
      # t.text :msg_response, default: %Q{We're away at the moment and will get back to you when we return .}

      t.string :sun_ct, default: WEEK_CT_VALUE
      t.string :sun_ot, default: WEEK_OT_VALUE

      t.string :mon_ct, default: WEEK_CT_VALUE
      t.string :mon_ot, default: WEEK_OT_VALUE

      t.string :tue_ct, default: WEEK_CT_VALUE
      t.string :tue_ot, default: WEEK_OT_VALUE

      t.string :wed_ct, default: WEEK_CT_VALUE
      t.string :wed_ot, default: WEEK_OT_VALUE

      t.string :thur_ct, default: WEEK_CT_VALUE
      t.string :thur_ot, default: WEEK_OT_VALUE

      t.string :fri_ct, default: WEEK_CT_VALUE
      t.string :fri_ot, default: WEEK_OT_VALUE

      t.string :sat_ct, default: WEEK_CT_VALUE
      t.string :sat_ot, default: WEEK_OT_VALUE

      t.timestamps null: false
    end

    add_index :away_messages, [:user_id]
  end
end
