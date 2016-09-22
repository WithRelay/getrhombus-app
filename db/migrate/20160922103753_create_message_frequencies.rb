# message frquency table holds the information of campaigns
class CreateMessageFrequencies < ActiveRecord::Migration
  def change
    create_table :message_frequencies do |t|
      t.timestamps null: false
      t.datetime :date
      t.datetime :time
      t.string :repeat_days
      t.integer :frequency_type
      t.string :delivery_type
      t.references :campaign
    end
    add_index :message_frequencies, [:campaign_id]
    add_foreign_key :message_frequencies, :campaigns, column: :campaign_id
  end
end
