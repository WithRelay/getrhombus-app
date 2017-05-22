class AddIsPlatformToMerchantCustomers < ActiveRecord::Migration
  def change
    add_column :merchant_customers, :is_platform, :integer, after: :managed_stripe_customer_id
  end
end
