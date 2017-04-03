
desc "move customer to merchant customer"
task :move_customer_to_merchant_customer => :environment do

  User.where(user_level: 0).each do |u|
  	if u.customer_uri.present?
  		MerchantCustomer.create(merchant_id: User.get_platform_acct_obj.id, 
  								customer_id: u.id, platform_stripe_customer_id: u.customer_uri)
  	end
  end
end
