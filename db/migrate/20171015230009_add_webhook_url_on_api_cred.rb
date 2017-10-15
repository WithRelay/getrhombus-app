class AddWebhookUrlOnApiCred < ActiveRecord::Migration
  def change
    add_column :api_creds, :webhook_url, :string, index: true
  end
end
