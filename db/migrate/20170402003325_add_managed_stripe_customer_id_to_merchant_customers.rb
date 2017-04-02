class AddManagedStripeCustomerIdToMerchantCustomers < ActiveRecord::Migration
  def change
  	rename_column :merchant_customers, :stripe_customer_id, :platform_stripe_customer_id
  	change_column :merchant_customers, :platform_stripe_customer_id, :string, after: :customer_id
  	add_column :merchant_customers, :managed_stripe_customer_id, :string, after: :platform_stripe_customer_id
  end
end
