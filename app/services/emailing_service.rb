class EmailingService
  require 'mandrill' # it is needed to run QUEUE=* rake resque:work
  MANDRILL = Mandrill::API.new Rails.application.secrets.mandrill['key']

  # Note there are a number of global settings for these emails in the mandrill account
  FROM_NAME = { edwin: 'Edwin from Relay', taiwo: 'Taiwo from Relay' }
  CALENDLY_LINK = Rails.application.secrets.calendly
  EMAIL_US_LINK = "mailto:#{Rails.application.secrets.team_email}"

  class << self
    delegate :url_helpers, to: 'Rails.application.routes'

    def sign_in_link; url_helpers.new_user_session_url end
    def sign_up_link; url_helpers.new_user_registration_url end

    def send_hosted_number_completed_notice(user)
      begin
        template_name = 'hosted-sms-activated'
        template_content = []
        message = { "subject" => "Your phone number is activated",
         "global_merge_vars"=> [ { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { 'name' => 'signin_link', 'content' => sign_in_link },
                                  { 'name' => 'howto_add_customers_link', 'content' => url_helpers.root_url },
                                  { 'name' => 'howto_accepts_payment_link', 'content' => url_helpers.root_url },
                                  { 'name' => 'howto_send_group_messages_link', 'content' => url_helpers.root_url }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def send_hosted_number_action_required_notice(hosted_number_order)
      begin
        template_name = 'hosted-sms-action-required'
        template_content = []
        message = { "subject" => "URGENT: Hosted SMS action required",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => 'team' },
                                  { "name" => "hosted_number_order", "content" => "#{hosted_number_order.id}"},
                                  { "name" => "hosted_number", "content" => "#{hosted_number_order.phone_number}"}
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => User.platform_email } ],
         "from_name" => "Email from Relay",
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def hosted_sms_progress_notice(user, rhombus_number)
      begin
        template_name = 'hosted-sms-progress'
        template_content = []
        message = { "subject" => "Status: Complete your phone number activation",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => 'team' },
                                  { "name" => "virtual_number", "content" => rhombus_number },
                                  { "name" => "verification_link", "content" => url_helpers.user_verify_hosted_sms_order_url(user) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def send_hosted_number_failed_notice(user)
      begin
        template_name = 'hosted-sms-failed'
        template_content = []
        message = { 'subject' => 'Status: Relay phone number activation',
         'global_merge_vars'=> [  { 'name' => 'first_name', 'content' => user.first_name || 'there' },
                                  { 'name' => 'virtual_number', 'content' => user.friendly_relay_number },
                                  { 'name' => 'signin_link', 'content' => sign_in_link }
                               ],
         'merge_language' => 'handlebars',
         'to'=> [ { 'email' => user.email } ],
         'bcc_address'=> User.platform_email,
         'from_name' => FROM_NAME[:edwin],
         'from_email' => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def send_email_campaign(campaign_hash, async)
      begin
        message = campaign_hash.merge({ "from_email" => User.platform_email })
        response = MANDRILL.messages.send(message, async)
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def charge_failure_notification(options = {})
      begin
        recipient = (options[:to_merchant]) ? options[:to] : User.platform_email
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
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # Welcome Email
    def welcome_email(user)
      begin
        template_name = "welcome-email"
        template_content = []
        message = { "subject" => "Welcome to Relay",
         "merge_language" => "handlebars",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { 'name' => 'calendly_link', 'content' => CALENDLY_LINK }
                               ],
         "bcc_address"=> User.platform_email,
         "to"=> [ { "email" => user.email } ],
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
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
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { 'name' => 'calendly_link', 'content' => CALENDLY_LINK }
                               ],
         "merge_language" => "handlebars",
         "bcc_address"=> User.platform_email,
         "to"=> [ { "email" => user.email } ],
         "from_name" => FROM_NAME[:taiwo],
         "from_email" => User.platform_email
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
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { 'name' => 'calendly_link', 'content' => CALENDLY_LINK }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:taiwo],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    #Features Tutorials
    def features_tutorials(user); end

    # Free Trial Expiration Notice (11 days after sign-up)
    def free_trial_expiration_notice(user)
      begin
        template_name = 'free-trial-expiration-notice'
        template_content = []
        message = { "subject" => "#{user.first_name || 'Hey there'}, your Relay trial ends in 3 days",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { "name" => "calendly_link", "content" => CALENDLY_LINK }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
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
         "global_merge_vars"=> [ { "name" => "first_name", "content" => user.first_name || 'there' } ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
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
        message = { 'subject' => 'It’s been a month',
         'merge_language' => 'handlebars',
         'global_merge_vars'=> [  { 'name' => 'first_name', 'content' => user.first_name || 'there' },
                                  { 'name' => 'calendly_link', 'content' => CALENDLY_LINK }
                               ],
         'to'=> [ { 'email' => user.email } ],
         'bcc_address'=> User.platform_email,
         'from_name' => FROM_NAME[:edwin],
         'from_email' => User.platform_email
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
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { 'name' => 'calendly_link', 'content' => CALENDLY_LINK }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
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
        message = { 'subject' => 'Checking in',
         'global_merge_vars'=> [  { 'name' => 'first_name', 'content' => user.first_name || 'there' },
                                  { 'name' => 'calendly_link', 'content' => CALENDLY_LINK }
                               ],
         'merge_language' => 'handlebars',
         'to'=> [ { 'email' => user.email } ],
         'bcc_address'=> User.platform_email,
         'from_name' => FROM_NAME[:edwin],
         'from_email' => User.platform_email
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
        template_name = 'exit-survey'
        template_content = []
        message = { "subject" => "Cancellation",
         "global_merge_vars"=> [ { "name" => "first_name", "content" => user.first_name || 'there' },
                                 { "name" => "calendly_link", "content" => CALENDLY_LINK }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def customer_import_campaigns(user); end

    def connect_facebook_messenger(user); end

    def add_bank_account(user); end

    def lists(user); end

    def customer_segmentation(user); end

    def in_chat_payments(user); end

    def pre_authorize_transactions(user); end

    def plans_and_subscriptions(user); end

    def saved_replies(user); end

    def message_reason(user); end

    def campaign_templates(user); end

    def set_customer_notifications(user); end

    def hashtag_keywords(user); end

    def first_time_message_auto_response(user); end

    def account_balance_alert(user)
      begin
        template_name = 'low-account-balance-template'
        template_content = []
        message = { "subject" => "Low account balance",
         "global_merge_vars" => [ { name: "first_name", content: user.first_name || 'there' },
                                  { name: "current_balance", content: Toolbox::Decimal.to_int_or_2dp(user.account_balance) },
                                  { name: "recharge_account_link", content: url_helpers.user_sms_usage_url(user) },
                                  { name: "set_auto_recharge_link", content: url_helpers.user_sms_usage_url(user) },
                                  { name: "help_center_link", content: url_helpers.root_url },
                                  { name: "email_us_link", content: EMAIL_US_LINK }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # transaction notification to merchant
    def customer_transaction_detail(options={})
      begin
        template_name = 'transaction-notification-template'
        template_content = []
        message = { "subject" => "#{options[:customer].first_name} sent you #{options[:currency_symbol]}#{options[:amount]}",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => options[:merchant].first_name || 'there' },
                                  { "name" => "customer_name", "content" => options[:customer].first_name },
                                  { "name" => "transaction_id", "content" => options[:transaction_id] },
                                  { "name" => "date", "content" => options[:created_at] },
                                  { "name" => "status", "content" => options[:status] },
                                  { "name" => "payment_method", "content" => "Visa **** **** **** #{options[:last4]} (Expiry #{options[:exp_month]}/#{options[:exp_year]})" },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "description", "content" => options[:description]},
                                  { "name" => "amount_less_fees", "content" => options[:amount_less_fees]},
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "transaction_link", "content" => url_helpers.user_transactions_url(options[:merchant]) },
                                  { "name" => "help_link", "content" => url_helpers.root_url },
                                  { "name" => "email_link", "content" => "mailto:#{User.platform_email}" },
                                  { "name" => "refer_link", "content" => url_helpers.user_refer_business_url(options[:merchant]) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:merchant].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # transaction notification to customer
    def customer_receipt(options = {})
      begin
        template_name = 'customer-receipt-template'
        template_content = []
        message = { "subject" => "You sent #{options[:currency_symbol]}#{options[:amount]} to #{options[:merchant].org_name}",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => options[:customer].first_name || 'there' },
                                  { "name" => "merchant_business_name", "content" => options[:merchant].org_name },
                                  { "name" => "transaction_id", "content" => options[:transaction_id] },
                                  { "name" => "date", "content" => options[:created_at] },
                                  { "name" => "status", "content" => options[:status] },
                                  { "name" => "payment_method", "content" => "Visa **** **** **** #{options[:last4]} (Expiry #{options[:exp_month]}/#{options[:exp_year]})" },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "description", "content" => options[:description]},
                                  { "name" => "taxes_and_fees", "content" => options[:taxes_and_fees] },
                                  { "name" => "total", "content" => options[:total_amount] },
                                  { "name" => "relay_number", "content" => options[:rhombus_number] },
                                  { "name" => "merchant_email", "content" => options[:merchant].email },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "transaction_link", "content" => url_helpers.user_transactions_url(options[:customer]) },
                                  { "name" => "relay_link", "content" => sign_up_link }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:customer].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => 'Relay',
         "from_email" => User.platform_email,
         "headers" => {
            "Reply-To" => options[:merchant].email
          },
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def refund_processed(options = {})
      begin
        template_name = 'refund-processed'
        template_content = []
        message = { "subject" => "Refund Processed",
         "global_merge_vars"=> [  { "name" => "merchant_first_name", "content" => options[:merchant_first_name] || 'there' },
                                  { "name" => "merchant_business_name", "content" => options[:merchant_business_name] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "refund_date", "content" => options[:date] },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "help_center_link", "content" => url_helpers.root_url },
                                  { "name" => "email_us_link", "content" => EMAIL_US_LINK },
                                  { "name" => "refer_business_link", "content" => url_helpers.user_refer_business_url(options[:user]) },
                                  { "name" => "billing_history_link", "content" => url_helpers.user_billing_information_url(options[:user]) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:user].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => 'Relay',
         "from_email" => User.platform_email,
         "headers" => {
            "Reply-To" => options[:merchant_email]
          },
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def subscription_failed(options = {})
      begin
        template_name = 'subscription-failed'
        template_content = []
        message = { "subject" => "Subscription Failed",
         "global_merge_vars"=> [  { "name" => "customer_first_name", "content" => options[:customer].first_name || 'there' },
                                  { "name" => "merchant_business_name", "content" => options[:merchant_business_name] },
                                  { "name" => "plan_name", "content" => options[:plan_name] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "frequency", "content" => options[:frequency] },
                                  { "name" => "failed_date", "content" => options[:failed_date] },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "help_center_link", "content" => url_helpers.root_url },
                                  { "name" => "email_us_link", "content" => EMAIL_US_LINK },
                                  { "name" => "dashboard_link", "content" => url_helpers.user_url(options[:customer]) },
                                  { "name" => "billing_history_link", "content" => url_helpers.user_billing_information_url(options[:customer]) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:customer].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email,
         "headers" => {
            "Reply-To" => options[:merchant_email]
          },
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def subscription_cancelled(options = {})
      begin
        template_name = 'subscription-cancelled'
        template_content = []
        message = { "subject" => "Subscription Cancelled",
         "global_merge_vars"=> [  { "name" => "customer_first_name", "content" => options[:customer].first_name || 'there' },
                                  { "name" => "merchant_business_name", "content" => options[:merchant].org_name },
                                  { "name" => "plan_name", "content" => options[:plan_name] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "cancellation_date", "content" => options[:cancellation_date] },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "help_center_link", "content" => url_helpers.root_url },
                                  { "name" => "email_us_link", "content" => EMAIL_US_LINK },
                                  { "name" => "refer_business_link", "content" => url_helpers.user_refer_business_url(options[:customer]) },
                                  { "name" => "billing_history_link", "content" => url_helpers.user_billing_information_url(options[:customer]) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:customer].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email,
         "headers" => {
            "Reply-To" => options[:merchant].email
          },
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def cancelled_subscription(options = {})
      begin
        template_name = 'cancelled-subscription'
        template_content = []
        message = { "subject" => "Cancelled Subscription",
         "global_merge_vars"=> [  { "name" => "merchant_first_name", "content" => options[:merchant].first_name || 'there' },
                                  { "name" => "customer_name", "content" => options[:customer].first_name },
                                  { "name" => "plan_name", "content" => options[:plan_name] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "cancellation_date", "content" => options[:cancellation_date] },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "customer_full_name", "content" => options[:customer].full_name },
                                  { "name" => "email", "content" => options[:customer].email },
                                  { "name" => "phone", "content" => options[:customer].phone },
                                  { "name" => "help_center_link", "content" => url_helpers.root_url },
                                  { "name" => "email_us_link", "content" => EMAIL_US_LINK },
                                  { "name" => "view_profile_link", "content" => url_helpers.user_merchant_customer_url(options[:merchant], options[:customer]) },
                                  { "name" => "message_customer_link", "content" => url_helpers.user_conversations_url(options[:merchant]) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:merchant].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def new_merchant_customer_subscription(options = {})
      begin
        template_name = 'new-merchant-customer-subscription'
        template_content = []
        message = { "subject" => "You have a new #{options[:currency_symbol]}#{options[:amount]} subscription",
         "global_merge_vars"=> [  { "name" => "merchant_first_name", "content" => options[:merchant].first_name || 'there' },
                                  { "name" => "customer_name", "content" => options[:customer].first_name || 'there' },
                                  { "name" => "transaction_id", "content" => options[:transaction_id] },
                                  { "name" => "plan_name", "content" => options[:plan_name] },
                                  { "name" => "frequency", "content" => options[:frequency] },
                                  { "name" => "transaction_date", "content" => options[:transaction_date] },
                                  { "name" => "payment_method", "content" => options[:payment_method] },
                                  { "name" => "description", "content" => options[:description] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "less_transaction_fees", "content" => options[:less_transaction_fees] },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "help_center_link", "content" => url_helpers.root_url },
                                  { "name" => "email_us_link", "content" => EMAIL_US_LINK },
                                  { "name" => "transaction_details_link", "content" => url_helpers.user_transactions_url(options[:merchant]) },
                                  { "name" => "refer_business_link", "content" => url_helpers.user_refer_business_url(options[:merchant]) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:merchant].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => 'Relay',
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def saas_subscription_receipt(options = {})
      begin
        template_name = 'subscription-receipt-template'
        template_content = []
        message = { "subject" => "Thank you for using Relay!",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => options[:merchant].first_name || 'there' },
                                  { "name" => "month", "content" => options[:month] },
                                  { "name" => "invoice_id", "content" => options[:stripe_invoice_id] },
                                  { "name" => "receipt_date", "content" => options[:date] },#February 23, 2017 | 1:30pm
                                  { "name" => "status", "content" => options[:status] },
                                  { "name" => "payment_method", "content" => options[:payment_method] },
                                  { "name" => "amount", "content" => options[:sub_total] },
                                  { "name" => "total", "content" => options[:total] },
                                  { "name" => "taxes_and_fees", "content" => options[:tax_and_fees] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  # { "name" => "pdf_download_link", "content" => url_helpers.root_url },
                                  { "name" => "billing_history_link", "content" => url_helpers.user_billing_information_url(options[:merchant]) },
                                  { "name" => "help_center_link", "content" => url_helpers.root_url },
                                  { "name" => "email_link", "content" => EMAIL_US_LINK },
                                  { "name" => "refer_business_link", "content" => url_helpers.user_refer_business_url(options[:merchant]) }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:merchant].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def sms_credit_receipt(options = {})
      begin
        template_name = 'sms-credit-receipt-template'
        template_content = []
        message = { "subject" => "Thank you for using Relay!",
         "global_merge_vars"=> [  { "name" => "merchant_first_name", "content" => options[:merchant].first_name || 'there' },
                                  { "name" => "transaction_id", "content" => options[:transaction_id] },
                                  { "name" => "transaction_date", "content" => options[:transaction_date] },#February 23, 2017 | 1:30pm
                                  { "name" => "status", "content" => options[:status] },
                                  { "name" => "payment_method", "content" => options[:payment_method] },
                                  { "name" => "amount", "content" => options[:amount] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "previous_balance", "content" => options[:previous_balance] },
                                  { "name" => "current_balance", "content" => options[:current_balance] },
                                  { "name" => "billing_history_link", "content" => url_helpers.user_billing_information_url(options[:merchant]) },
                                  { "name" => "help_center_link", "content" => url_helpers.root_url },
                                  { "name" => "email_us_link", "content" => EMAIL_US_LINK },
                                  { "name" => "refer_a_business_link", "content" => url_helpers.user_refer_business_url(options[:merchant]) },
                                  { "name" => "auto_recharge_link", content: url_helpers.user_sms_usage_url(options[:merchant]) },
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:merchant].email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => 'Relay',
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # send data for new message
    def unread_message_notification(to, options = {})
      begin
        template_name = 'unread-messages-notification'
        template_content = []
        message = { 'subject' => 'You have a new unread message',
         'global_merge_vars'=> [  { 'name' => 'customer_first_name', 'content' => options[:merchant].first_name || 'there' },
                                  { 'name' => 'sender_name', 'content' => options[:sender_name] },
                                  { 'name' => 'sender_email', 'content' => options[:sender_email] },
                                  { 'name' => 'message', 'content' => options[:message] },
                                  { 'name' => 'message_time', 'content' => options[:message_time] },
                                  { 'name' => 'sender_profile_url', 'content' => options[:sender_profile_url] },
                                  { 'name' => 'sign_in_url', 'content' => sign_in_link },
                                  { 'name' => 'notification_setting_link', 'content' => url_helpers.user_notifications_url(options[:merchant]) },
                                  { 'name' => 'conversation_dashboard_link', 'content' => url_helpers.user_conversations_url(options[:merchant]) }
                               ],
         'merge_language' => 'handlebars',
         'to'=> to,
         'bcc_address'=> User.platform_email,
         'from_name' => FROM_NAME[:edwin],
         'from_email' => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def referral_bonus_email(email, referred_first_name, referrer_first_name)
      begin
        template_name = 'referrer-email-template'
        template_content = []
        message = { 'subject' => 'You were Referred to Relay',
         'global_merge_vars'=> [  { 'name' => 'referred_first_name', 'content' => referred_first_name },
                                  { 'name' => 'referrer_first_name', 'content' => referrer_first_name },
                                  { 'name' => 'relay_link', 'content' => url_helpers.root_url },
                                  { 'name' => 'learn_more_link', 'content' => sign_up_link },
                                  { 'name' => 'claim_referral_bonus_link', 'content' => url_helpers.root_url }
                               ],
         'merge_language' => 'handlebars',
         "to"=> [ { "email" => email } ],
         'bcc_address'=> User.platform_email,
         'from_name' => FROM_NAME[:edwin],
         'from_email' => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def incomplete_sign_up(user)
      begin
        template_name = 'incomplete-sign-up'
        template_content = []
        message = { "subject" => "Incomplete account setup",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { "name" => "calendly_link", "content" => CALENDLY_LINK }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def auto_reload_failure(user)
      begin
        template_name = 'auto-reload-failure'
        template_content = []
        message = { "subject" => "Auto-reload Failure",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { "name" => "signin_link", "content" => sign_in_link },
                                  { "name" => "calendly_link", "content" => CALENDLY_LINK }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
        puts e
      end
    end

    def customer_sign_up(user)
      begin
        template_name = 'customer-sign-up'
        template_content = []
        message = { "subject" => "Welcome to Relay",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { "name" => "refer_business_link", "content" => url_helpers.user_refer_business_url(user) },
                                  { "name" => "signup_link", "content" => sign_up_link }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def customer_sign_up_from_referral_link(user, merchant)
      begin
        template_name = 'customer-sign-up-from-referral-link'
        template_content = []
        message = { "subject" => "Welcome to Relay",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { "name" => "business_name", "content" => merchant.org_name },
                                  { "name" => "relay_number", "content" => merchant.friendly_relay_number }
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => user.email } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def customer_added_to_relay(user, merchant, temp_password)
      begin
        template_name = 'customer-added-to-relay'
        template_content = []
        message = { "subject" => "Best way to reach us",
          "global_merge_vars"=> [ { "name" => "first_name", "content" => user.first_name || 'there' },
                                  { "name" => "business_name", "content" => merchant.org_name },
                                  { "name" => "signin_link", "content" => sign_in_link },
                                  { "name" => "relay_number", "content" => merchant.friendly_relay_number },
                                  { "name" => "customer_email", "content" => user.email },
                                  { "name" => "temp_password", "content" => temp_password }
                               ],
          "merge_language" => "handlebars",
          "to"=> [ { "email" => user.email } ],
          "bcc_address"=> User.platform_email,
          "from_name" => merchant.user_title,
          "from_email" => User.platform_email,
          "headers" => {
            "Reply-To" => merchant.email
          },
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # to platform only
    def customer_subscription_updated(merchant, plan_name, subscription_id)
      begin
        template_name = 'customer-subscription-updated'
        template_content = []
        message = { "subject" => "Subscription updated",
          "global_merge_vars"=> [{ "name" => "first_name", "content" => merchant.first_name || 'there' },
            { "name" => "plan_name", "content" => plan_name },
            { "name" => "subscription_id", "content" => subscription_id }
          ],
          "merge_language" => "handlebars",
          "to"=> [ { "email" => User.platform_email } ],
          "from_name" => "Email from Relay",
          "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # to platform only
    def invoice_created(invoice)
      begin
        template_name = 'invoice-created'
        template_content = []
        message = { 'subject' => 'Invoice Created',
          "global_merge_vars"=> [{ "name" => "first_name", "content" => 'Team' },
            { 'name' => 'id', 'content' => invoice.id },
            { 'name' => 'subscription_id', 'content' => invoice.subscription_id },
          ],
          'merge_language' => 'handlebars',
          'to'=> [ { 'email' => User.platform_email } ],
          'from_name' => 'Email from Relay',
          'from_email' => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def invoice_payment_succeeded(merchant_email, customer)
      begin
        template_name = 'invoice-payment-succeed'
        template_content = []
        message = { 'subject' => 'Subscription Renewed',
          'global_merge_vars'=> [{ 'name' => 'first_name', 'content' => customer.first_name || 'there' },
            { 'name' => 'id', 'content' => invoice.id },
            { 'name' => 'subscription_id', 'content' => invoice.subscription_id },            # other invoice data will be here according to email template
          ],
          'merge_language' => 'handlebars',
          'to'=> [ { 'email' => customer.email } ],
          "bcc_address"=> User.platform_email,
          'from_name' => FROM_NAME[:edwin],
          'from_email' => User.platform_email,
          "headers" => {
            "Reply-To" => merchant_email
          },
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    # to platform only
    def customer_source_updated(customer)
      begin
        template_name = 'customer-source-updated'
        template_content = []
        message = { 'subject' => 'Customer Source Updated',
          'global_merge_vars'=> [{ 'name' => 'first_name', 'content' => customer.first_name || 'there' }],
          'merge_language' => 'handlebars',
          'to'=> [ { 'email' => User.platform_email } ],
          'from_name' => 'Email from Relay',
          'from_email' => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end

    def send_weekly_mail(options = {})
      template_name = "weekly-summary-template"
      remaining_people_count = options[:new_people_count] > 5 ? "+#{options[:new_people_count] - 5} more" : ""
      template_content = []
        message = { "subject" => "Weekly Summary",
         "global_merge_vars"=> [  { "name" => "first_name", "content" => options[:first_name] || 'there' },
                                  { "name" => "week_stamp", "content" => options[:week_stamp] },
                                  { "name" => "new_people_count", "content" => options[:new_people_count] },
                                  { "name" => "remaining_people_count", "content" => remaining_people_count},
                                  { "name" => "transactions_count", "content" => options[:transactions_count] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "total_amount", "content" => options[:total_amount] },
                                  { "name" => "net_sales", "content" => options[:net_sales] },
                                  { "name" => "subscription_count", "content" => options[:subscription_count] },
                                  { "name" => "subscription_charges", "content" => options[:subscription_charges] },
                                  { "name" => "net_charges", "content" => options[:net_charges] },
                                  { "name" => "messages_count", "content" => options[:messages_count] },
                                  { "name" => "message_difference", "content" => options[:message_difference] },
                                  { "name" => "sms_percent", "content" => options[:sms_percent] },
                                  { "name" => "fb_message_percent", "content" => options[:fb_message_percent] },
                                  { "name" => "open_conversation_count", "content" => options[:open_conversation_count] },
                                  { "name" => "taxes_and_fees", "content" => options[:tax_and_fees] },
                                  { "name" => "currency", "content" => options[:currency] },
                                  { "name" => "currency_symbol", "content" => options[:currency_symbol] },
                                  { "name" => "dashboard_link", "content" => sign_in_link },
                                  { "name" => "peoples_list", "content" => options[:peoples_list]}
                               ],
         "merge_language" => "handlebars",
         "to"=> [ { "email" => options[:user_email] } ],
         "bcc_address"=> User.platform_email,
         "from_name" => FROM_NAME[:edwin],
         "from_email" => User.platform_email
        }
        async = true
        result = MANDRILL.messages.send_template template_name, template_content, message, async
      rescue Mandrill::Error => e   # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
      rescue StandardError => e
      end
    end
  end
