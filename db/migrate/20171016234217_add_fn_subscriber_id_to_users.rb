class AddFnSubscriberIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :fn_subscriber_id, :string, after: :rn_country
  end
end
