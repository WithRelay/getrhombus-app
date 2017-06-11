class AddStatusEventOnHostedSms < ActiveRecord::Migration
  def change
    add_column :hosted_sms, :status_events, :text
  end
end
