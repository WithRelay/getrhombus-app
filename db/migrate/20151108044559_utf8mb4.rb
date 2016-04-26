class Utf8mb4 < ActiveRecord::Migration
    
    # http://tech.taskrabbit.com/blog/2014/04/24/active-record-mysql-and-emoji/
    # http://blog.arkency.com/2015/05/how-to-store-emoji-in-a-rails-app-with-a-mysql-database/
    # https://mzsanford.wordpress.com/2010/12/28/mysql-and-unicode/

    UTF8_TEXT = {
        'hashtags' => 'response',
        'messages' => 'text',
        'transactions' => 'notes',
        'users' => 'custom_welcome'
    }

    UTF8_VARCHAR = [
      	{ 'schema_migrations' => 'version' }, 
        { 'hashtags' => 'name' }, 
        { 'hashtags' => 'tag' },  
        { 'messages' => 'from' }, 
        { 'messages' => 'to' }, 
        { 'messages' => 'message_timestamp' },
        { 'messages' => 'message_price' },
        { 'messages' => 'scts' },
        { 'messages' => 'client_ref' },
        { 'messages' => 'status' },
        { 'messages' => 'status_delivery' },
        { 'messages' => 'network_code' },
        { 'messages' => 'error_text' },
        {'messages' => 'err_code' },
        {'messages' => 'messageId' },  
        {'transactions' => 'transaction_uri' },
        {'transactions' => 'transaction_number' },
        {'transactions' => 'description' },
        {'transactions' => 'from' },
        {'transactions' => 'to' },
        {'transactions' => 'status' },
        {'transactions' => 'transaction_available_at' },
        {'transactions' => 'last_four' },
        {'transactions' => 'expiration_month' },
        {'transactions' => 'expiration_year' },
        {'transactions' => 'zip_code' },
        {'transactions' => 'card_type' },
    	{'transactions' => 'card_name' },
        {'transactions' => 'tax_rate' },
        {'transactions' => 'on_behalf_of_uri' },
        {'transactions' => 'account_number' },
        {'transactions' => 'account_type' },
        {'transactions' => 'account_name' },
        {'transactions' => 'routing_number' },
        {'transactions' => 'referenced_customer_transaction_id' },
        {'transactions' => 'receipt_sent_at' },
        {'transactions' => 'refund_reason' },
        {'transactions' => 'currency' },
        {'users' => 'email' },
        {'users' => 'encrypted_password' },
        {'users' => 'reset_password_token' },
        {'users' => 'current_sign_in_ip' },
        {'users' => 'last_sign_in_ip' },
        {'users' => 'confirmation_token'},
        {'users' => 'unconfirmed_email' },
        {'users' => 'customer_uri' },
        {'users' => 'last_four' },
        {'users' => 'expiration_month' },
        {'users' => 'expiration_year' },
        {'users' => 'zip_code' },
        {'users' => 'card_type' },
        {'users' => 'card_name' },
        {'users' => 'phone_number' },
        {'users' => 'business_name' },
        {'users' => 'business_type' },
        {'users' => 'street_address' },
        {'users' => 'city' },
        {'users' => 'state_province' },
        {'users' => 'business_phone' },
        {'users' => 'country' },
        {'users' => 'rhombus_number' },
        {'users' => 'routing_number' },
        {'users' => 'account_name' },
        {'users' => 'account_number' },
        {'users' => 'account_type' },
        {'users' => 'tax_rate' },
        {'users' => 'instrument_uri' },
        {'users' => 'business_zip_code' },
        {'users' => 'provider' },
        {'users' => 'uid' },
        {'users' => 'stripe_access_token' },
        {'users' => 'stripe_publishable_key' },
        {'users' => 'stripe_scope' },
        {'users' => 'stripe_livemode' },
        {'users' => 'stripe_refresh_token' },
        {'users' => 'first_name' },
        {'users' => 'last_name' },
        {'users' => 'referrer_num' },
        {'users' => 'url' },
        {'users' => 'short_url' },
        {'users' => 'currency' }
    ]

    def self.up
        execute "ALTER DATABASE `#{ActiveRecord::Base.connection.current_database}` CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin;"

        UTF8_VARCHAR.each do |c|
            c.each { |k,v| execute "ALTER TABLE `#{k}` CHANGE `#{v}` `#{v}` VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;" }
        end

        UTF8_TEXT.each do |table, col|
          execute "ALTER TABLE `#{table}` CHANGE `#{col}` `#{col}` TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
        end

        ActiveRecord::Base.connection.tables.each do |table|
          execute "ALTER TABLE `#{table}` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
        end
    end

    def self.down
        execute "ALTER DATABASE `#{ActiveRecord::Base.connection.current_database}` CHARACTER SET = utf8 COLLATE = utf8_general_ci;"

        UTF8_VARCHAR.each do |c|
            c.each { |k,v| execute "ALTER TABLE `#{k}` CHANGE `#{v}` `#{v}` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci;" }      
        end

        UTF8_TEXT.each do |table, col|
          execute "ALTER TABLE `#{table}` CHANGE `#{col}` `#{col}` TEXT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        end

        ActiveRecord::Base.connection.tables.each do |table|
          execute "ALTER TABLE `#{table}` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;"
        end   
     end

end

