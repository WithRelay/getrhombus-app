class EmailingService

  require 'mandrill' # it is need to run QUEUE=* rake resque:work
  MANDRILL = Mandrill::API.new Rails.application.secrets.mandrill["key"]

  # Note there are a number of global settings for this email in the mandrill account
   SENDER = Rails.application.secrets.team_email
   FROM_EMAIL= { edwin: "<redacted_email>", ovo: '<redacted_email>' }
  class << self

    def send_email_campaign(campaign_hash)
      # Email camapign is not only used to send email campaign but also facebook messenger camapign
      # and facebook messenger camapaign do not contain subject
      campaign_hash[:subject] = "Rhombus Campaign" if campaign_hash[:subject].blank?
      message = campaign_hash.merge(FROM_EMAIL)
      response = MANDRILL.messages.send(message)
      ['sent', 'queued'].include?(response[0]['status']) ? true : false
    end

    def send_welcome_email_with_referral(merchant_email, to, merchant_name, rhombus_number, rhombus_team_number)
      begin
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
        result = MANDRILL.messages.send_template template_name, template_content, message, async
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
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def send_receipt(options = {})
      begin
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
        result = MANDRILL.messages.send_template template_name, template_content, message, async
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
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Welcome Email (15 minutes after sign-up)
    def welcome_email(user)
      begin
        template_name = "welcome-email"
        template_content = []
        message = { "subject" => "Welcome to Relay",
         "merge_language" => "handlebars",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "bcc_address"=> SENDER,
         "to"=> [ { "email" => user.email } ],
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Proactive Support Email (2 days after sign-up)
    def send_proactive_support_email(user)
      begin
        template_name = "proactive-support-email"
        template_content = []
        message = { "subject" => "Get the most out of Relay",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "merge_language" => "handlebars",
         "bcc_address"=> SENDER,
         "to"=> [ { "email" => user.email } ],
         "from_name" => "Ovo from Relay",
         "from_email" => FROM_EMAIL[:ovo]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Schedule Demo Email (4 days after sign-up)
    def schedule_demo_email(user)
      begin
        template_name = 'schedule-demo-email'
        template_content = []
        message = { "subject" => "Schedule a live walk-through of Relay",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Ovo from Relay",
         "from_email" => FROM_EMAIL[:ovo]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    #Features Tutorials
    def features_tutorials(user)
    end

    # Free Trial Expiration (14 days after sign-up)
    def free_trial_expiration(user)
      begin
        template_name = 'free-trial-expiration'
        template_content = []
        message = { "subject" => "Your Relay Trial",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Weekly Activity Summary (HTML Template, Every Monday - 11am)
    def weekly_activity_summary(user)
      begin
        template_name = 'weekly-activity-summary'
        template_content = []
        message = { "subject" => "Relay: Weekly activity summary",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Relay Report",
         "from_email" => SENDER
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # One-month Follow-up (31 Days after sign-up)
    def one_month_followup(user)
      begin
        template_name = 'one-month-follow-up'
        template_content = []
        message = { "subject" => "It’s been a month",
         "merge_language" => "handlebars",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Three month Follow-up (91 Days after sign-up)
    def three_month_followup(user)
      begin
        template_name = 'three-month-follow-up'
        template_content = []
        message = { "subject" => "It’s been a 3 months",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Offer to Help (7 Days after signup, IF Zero Account Activity)
    def offer_to_help(user)
      begin
        template_name = 'offer-to-help'
        template_content = []
        message = { "subject" => "Checking in",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Exit Survey (IF Account is Cancelled)
    def exit_survey(user)
      begin
        template_name = 'free-trial-expiration'
        template_content = []
        message = { "subject" => "Cancellation",
         "global_merge_vars"=> [    { "name" => "first_name", "content" => user.full_name.split.first || 'there' } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def send_unread_message_alert(options = {})
      begin
        mandrill = Mandrill::API.new MANDRILL_API_KEY
        template_name = 'unread-messages'
        template_content = []
        message = { "subject"=>"Unread Message Notification",
         "global_merge_vars"=> [ { "name" => "unread_count", "content" => options[:unread_count] },
                                 { "name" => "pluralize_msg", "content" => options[:pluralize_msg] } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:to] } ],
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

    def customer_import_campaigns(user)
    end

    def connect_facebook_messenger(user)
    end

    def add_bank_account(user)
    end

    def lists(user)
    end

    def customer_segmentation(user)
    end

    def in_chat_payments(user)
    end

    def pre_authorize_transactions(user)
    end

    def plans_and_subscriptions(user)
    end

    def saved_replies(user)
    end

    def message_reason(user)
    end

    def campaign_templates(user)
    end

    def set_customer_notifications(user)
    end

    def hashtag_keywords(user)
    end

    def first_time_message_auto_response(user)
    end

    def send_demo_notifcation(demo)
    end

    def account_balance_alert(user)
      begin
        template_name = 'low-account-balance'
        template_content = []
        message = { "subject" => "Low account balance",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.full_name.split.first || 'there' },
                                  { "name" => "account_balance", "content" => user.account_balance }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def merchant_transaction_detail(transaction)
      begin
        template_name = 'transaction-details'
        template_content = []
        message = { "subject" => "You sent #{transaction.amount} to #{transaction.team.org_name}",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => transaction.user.full_name.split.first || 'there' },
                                  { "name" => "merchant_business_name", "content" => transaction.user.org_name },
                                  { "name" => "transaction_id", "content" => transaction.id },
                                  { "name" => "date", "content" => transaction.created_at },
                                  { "name" => "status", "content" => transaction.status },
                                  { "name" => "payment_method", "content" => '' }
                                  { "name" => "amount", "content" => transaction.amount },
                                  { "name" => "discription", "content" => },
                                  { "name" => "taxes_and_fees", "content" => }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def transaction_receipt(transaction)
      begin
        template_name = 'transaction_receipt'
        template_content = []
        message = { "subject" => "Receipt",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => transaction.user.full_name.split.first || 'there' },
                                  { "name" => "transaction_id", "content" => transaction.id },
                                  { "name" => "date", "content" => transaction.created_at },
                                  { "name" => "status", "content" => transaction.status },
                                  { "name" => "payment_method", "content" => '' }
                                  { "name" => "amount", "content" => transaction.amount },
                                  { "name" => "previous_balance", "content" => '' },
                                  { "name" => "current_balance", "content" => '' }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def transaction_reminder(transaction)
      begin
        template_name = 'transaction-details'
        template_content = []
        message = { "subject" => "Thank you for using Relay!",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => transaction.team.full_name.split.first || 'there' },
                                  { "name" => "merchant_business_name", "content" => transaction.user.org_name },
                                  { "name" => "transaction_id", "content" => transaction.id },
                                  { "name" => "date", "content" => transaction.created_at },
                                  { "name" => "status", "content" => transaction.status },
                                  { "name" => "payment_method", "content" => '' }
                                  { "name" => "amount", "content" => transaction.amount },
                                  { "name" => "discription", "content" => },
                                  { "name" => "taxes_and_fees", "content" => }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def customer_transaction_detail(transaction)
      begin
        template_name = 'transaction-details'
        template_content = []
        message = { "subject" => "#{transaction.user.full_name} sent you #{transaction.amount}",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => transaction.team.full_name.split.first || 'there' },
                                  { "name" => "merchant_business_name", "content" => transaction.user.org_name },
                                  { "name" => "transaction_id", "content" => transaction.id },
                                  { "name" => "date", "content" => transaction.created_at },
                                  { "name" => "status", "content" => transaction.status },
                                  { "name" => "payment_method", "content" => '' }
                                  { "name" => "amount", "content" => transaction.amount },
                                  { "name" => "discription", "content" => },
                                  { "name" => "taxes_and_fees", "content" => }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> SENDER,
         "from_name" => "Edwin from Relay",
         "from_email" => FROM_EMAIL[:edwin]
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def unread_message_reminders
    end

  end

end
