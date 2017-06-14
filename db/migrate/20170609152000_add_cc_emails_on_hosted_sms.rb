class AddCcEmailsOnHostedSms < ActiveRecord::Migration
  def change
    add_column :hosted_sms, :cc_emails, :string, array: true, default: []
  end
end
