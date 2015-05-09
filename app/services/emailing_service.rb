class EmailingService
  require 'mandrill'
  MANDRILL_API_KEY = Rails.application.secrets.mandrill["key"]
  # Note there are a number of global settings for these emails in the mandrill account
  SENDER = Rails.application.secrets.team_email

  class << self
    
    def send_welcome_email_with_referral(sender, to, merchant_name, rhombus_number, rhombus_team_number)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = "welcome-email-with-referral-customers"
        template_content = []
        message = { "subject"=>"Welcome to Rhombus",
         "merge_vars"=>
            [ { "vars"=> [ { "rhombus_team_number" => rhombus_team_number, "rhombus_number" => rhombus_number,
                              "merchant_name" => merchant_name } ],
                "rcpt"=> to } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => to } ],
         "from_name" => "Rhombus",
         "from_email" => sender 
        }
        result = mandrill.messages.send_template template_name, template_content, message        
      rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end  
    end

    def send_welcome_email(to, rhombus_team_number, user)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = (user == "merchant") ? "welcome-email-merchants" : "welcome-email-customers"
        template_content = []
        message = { "subject"=>"Welcome to Rhombus",
         "merge_vars"=>
            [ { "vars"=> [ { "rhombus_team_number" => rhombus_team_number } ],
                "rcpt"=> to } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => to } ],
         "from_name" => "Rhombus",
         "from_email" => SENDER 
        }
        result = mandrill.messages.send_template template_name, template_content, message        
      rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end  
    end

=begin
    def send_receipt(options)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'receipt'
        template_content = []
        message = { "subject"=>"You sent a payment with Rhombus",
         "merge_vars"=>
            [ { "vars"=> [ { "merchant_name" => options[:merchant_name], "transaction_number" => options[:transaction_number],
                              'transaction_date' =>  , 'text_message' => options[:text], 'amount' => options[:amount],
                              'taxes' => options[:taxes], 'amount_with_taxes' => options[:amount_with_taxes],
                              'business_phone' => options[:business_phone]
                               } ],
                "rcpt"=> options[:to] } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:to] } ],
         "from_email" => options[:sender]
        }
        result = mandrill.messages.send_template template_name, template_content, message        
      rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end  
    end
=end

    def text_failure_notification(dump, from, to, message)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'nexmo-api-error'
        template_content = []
        message = { "subject"=>"Nexmo api error",
         "merge_vars"=>
            [ { "vars"=> [ { "dump" => dump, "message_from" => from,
                              'message_to' => to, 'content' => message } ],
                "rcpt"=> SENDER } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => SENDER } ],
         "from_email" => SENDER
        }
        result = mandrill.messages.send_template template_name, template_content, message        
      rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end  
    end

    def token_failure_notification(dump, customer_email)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'failed-to-tokenize'
        template_content = []
        message = { "subject"=>"Tokenization failure",
         "merge_vars"=>
            [ { "vars"=> [ { "customer_email" => customer_email, "dump" => dump } ],
                "rcpt"=> SENDER } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => SENDER } ],
         "from_email" => SENDER
        }
        result = mandrill.messages.send_template template_name, template_content, message        
      rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end  
    end

    def send_receipt(options)
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'charge-failure'
        template_content = []
        message = { "subject"=>"Charge Failure",
         "merge_vars"=>
            [ { "vars"=> [ { "customer_email" => options[:customer_email], "customer_phone" => options[:customer_phone],
                              'text_message' => options[:text], 'card_name' => options[:card_name],
                              'last_four' => options[:last_four], 'merchant_email' => options[:merchant_email],
                              'business_phone' => options[:business_phone], 'rhombus_number' => options[:rhombus_number],
                                'dump' => options[:dump]
                               } ],
                "rcpt"=> options[:to] } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:to] } ],
         "from_email" => options[:sender]
        }
        result = mandrill.messages.send_template template_name, template_content, message        
      rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      end  
    end

  end  

end

