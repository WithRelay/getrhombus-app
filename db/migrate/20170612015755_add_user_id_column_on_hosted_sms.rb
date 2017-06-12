class AddUserIdColumnOnHostedSms < ActiveRecord::Migration
  def change
    add_column :hosted_sms, :user_id, :integer
  end
end
