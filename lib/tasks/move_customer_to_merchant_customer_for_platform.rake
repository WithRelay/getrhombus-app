
# TASK 3

desc "move customer to merchant customer"
task :move_customer_to_merchant_customer_for_platform => :environment do
  users = User.where(user_level: 0)
  puts "Going to update #{users.count} users"

  ActiveRecord::Base.transaction do
    users.each do |user|
      puts user.email

      if user.customer_uri.present?
        puts "#{user.customer_uri}"
        re = TextingService.get_customer_card_id(user.customer_uri)
        if re.first
          puts "#{user.customer_uri} => #{re.first}"
          user.update!(card_id: re.first) 
        end
      end

    	MerchantCustomer.find_or_create_by!(merchant_id: User.get_platform_acct_obj.id, customer_id: user.id, 
                               platform_stripe_customer_id: (user.customer_uri.present? ? user.customer_uri : nil))

      puts "Created Merchant customer \n"
    end
  end
end

# Then
# 1. write migration to remove the customer uri column after migration
# 2. get card_id from stripe api to store in card_id column

# Note 
# Need to test that the customer_uri actually belongs to the platform
