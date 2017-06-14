class AddCapabilitiesOnHostedSms < ActiveRecord::Migration
  def change
    add_column :hosted_sms, :capabilities, :text
  end
end
