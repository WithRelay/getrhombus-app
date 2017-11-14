
# TASK 3. Tested

# CANT REALLY TEST THIS SINCE CUSTOMER URI IS IN LIVE MODE ONLY.

desc "move customer to merchant customer"
task :move_customer_to_merchant_customer_for_platform => :environment do
  users = User.where("id > 1")
  puts "Going to update #{users.count} users"

  ActiveRecord::Base.transaction do
    users.each do |user|
      puts user.email

      if user.customer_uri.present?
        puts "#{user.customer_uri}"
        re = PaymentService.get_customer_card_id(user.customer_uri)
        if re.first
          # get last four, expirate dates, card name *************************************
          puts "#{user.customer_uri} => #{re.first}"
          user.update!(card_id: re.first) 
        end
      end

    	merchant_customer = MerchantCustomer.where(merchant_id: 1, customer_id: user.id).first_or_create!(is_platform: 0,
                               platform_stripe_customer_id: (user.customer_uri.present? ? user.customer_uri : nil))

      merchant_customer.update!(created_at: user.created_at, updated_at: user.updated_at)
      puts merchant_customer.inspect
      puts "Created Merchant customer \n"
    end
  end
end

# Then
# 1. write migration to remove the customer uri column after migration
# 2. get card_id from stripe api to store in card_id column

# Note 
# Need to test that the customer_uri actually belongs to the platform
