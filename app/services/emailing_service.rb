class EmailingService
  
  require 'mandrill' # dont think i need to require here again...check

  MANDRILL_API_KEY = Rails.application.secrets.mandrill["key"]
  
  # Note there are a number of global settings for this email in the mandrill account
  SENDER = Rails.application.secrets.team_email

  class << self
    
    def send_welcome_email_with_referral(merchant_email, to, merchant_name, rhombus_number, rhombus_team_number)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = "welcome-email-with-referral-customers"
        template_content = []
        message = { "subject" => "Welcome to Rhombus",
         "global_merge_vars" => [ { "name" => "rhombus_team_number", "content" => rhombus_team_number }, 
                                  { "name" => "rhombus_number", "content" => rhombus_number },
                                  { "name" => "merchant_name", "content" => merchant_name } ],
         "merge_language" => "handlebars",
         "bcc_address"=> SENDER,
         "to"=> [ { "email" => to } ],
         "from_name" => "Rhombus",
         "from_email" => SENDER
        }
        async = true
        result = mandrill.messages.send_template template_name, template_content, message, async       
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end  
    end

    def send_welcome_email(to, rhombus_team_number, user_type)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = (user_type == "merchant") ? "welcome-email-merchants" : "welcome-email-customers"
        template_content = []
        message = { "subject" => "Welcome to Rhombus",
         "merge_language" => "handlebars",
         "global_merge_vars" => [ { "name" => "rhombus_team_number", "content" => rhombus_team_number } ],
         "to"=> [ { "email" => to } ],
         "bcc_address"=> SENDER,
         "from_name" => "Rhombus",
         "from_email" => SENDER 
        }
        async = true
        result = mandrill.messages.send_template template_name, template_content, message, async        
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end  
    end

    def send_receipt(options = {})
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'receipt'
        template_content = []
        message = { "subject"=>"You sent a payment with Rhombus",
         "global_merge_vars"=> [ { "name" => "merchant_name", "content" => options[:merchant_name] }, 
                                 { "name" => 'merchant_email', "content" => options[:merchant_email] }, 
                                 { "name" => "transaction_number", "content" => options[:transaction_number] },
                                 { "name" => 'transaction_date', "content" => options[:transaction_date] }, 
                                 { "name" => 'text_message', "content" => options[:text] }, 
                                 { "name" => 'amount', "content" => options[:amount] },
                                 { "name" => 'amount_with_taxes', "content" => options[:amount_with_taxes] }, 
                                 { "name" => 'business_phone', "content" => options[:org_phone] },
                                 { "name" => "currency", "content" => options[:currency] } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:to] } ],
         "from_name" => options[:merchant_name],
         "from_email" => SENDER
        }
        async = true
        result = mandrill.messages.send_template template_name, template_content, message, async        
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end 
    end

    def send_payment_notification(options = {})
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'payment-notification-merchants'
        template_content = []
        message = { "subject"=>"You received a payment with Rhombus",
         "global_merge_vars"=> [ { "name" => "card_name", "content" => options[:card_name] }, 
                                 { "name" => "last_four", "content" => options[:last4] }, 
                                 { "name" => "card_type", "content" => options[:card_type] }, 

                                 { "name" => "customer_email", "content" => options[:customer_email] }, 
                                 { "name" => "customer_phone", "content" => options[:customer_phone] },
                                 { "name" => 'text_message', "content" => options[:text] }, 
                                 
                                 { "name" => "transaction_number", "content" => options[:transaction_number] },
                                 { "name" => "stripe_txn_number", "content" => options[:stripe_txn_number] },
                                 { "name" => 'transaction_date', "content" => options[:transaction_date] }, 
                                 
                                 { "name" => 'amount_less_fees', "content" => options[:amount_less_fees] },
                                 { "name" => 'amount_with_taxes', "content" => options[:amount_with_taxes] }, 
                                 { "name" => 'rhombus_number', "content" => options[:rhombus_number] },
                                 { "name" => "currency", "content" => options[:currency] } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:to] } ],
         "from_name" => "Rhombus",
         "from_email" => SENDER
        }
        async = true
        result = mandrill.messages.send_template template_name, template_content, message, async       
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end 
    end

    def charge_failure_notification(options = {})
      begin
        recipient = (options[:to_merchant]) ? options[:to] : SENDER
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'charge-failure'
        template_content = []
        message = { "subject"=>"Charge Failure",
         "global_merge_vars"=> [  { "name" => "customer_email", "content" => options[:customer_email] }, 
                                  { "name" => "customer_phone", "content" => options[:customer_phone] },                                  
                                  { "name" => "card_name", "content" => options[:card_name] }, 
                                  { "name" => "last_four", "content" => options[:last4] },
                                  { "name" => 'text_message', "content" => options[:text] }, 
                                  { "name" => 'merchant_email', "content" => options[:to] }, 
                                  { "name" => "business_phone", "content" => options[:org_phone] },                                  
                                  { "name" => 'rhombus_number', "content" => options[:rhombus_number] },
                                  { "name" => "dump", "content" => options[:dump].to_s } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => recipient } ],
         "bcc_address"=> SENDER,
         "from_name" => "Rhombus",
         "from_email" => SENDER
        }
        async = true
        result = mandrill.messages.send_template template_name, template_content, message, async      
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end 
    end

    def send_founder_welcome_email(user)
      puts "send founder welcome email"
      puts user
      puts "\n"
    end

    def send_proactive_support_email(user)
      puts "send proactive support email"
      puts user
      puts "\n"
    end

    def schedule_demo_email(user)
      puts "send demo email"
      puts user
      puts "\n"
    end

    def send_unread_message_alert(data)
      puts data.email
      puts data.unread_count
      puts data.sms_number
      puts "\n"
    end

  end  

end
