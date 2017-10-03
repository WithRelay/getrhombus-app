class MessageParser

  ## TEST captured link for sign in

  include Transactionable

  # Message/FbMessage object must exist when calling this method
  # from can be user fb cred or phone number
  # customer can be nil
  def process_message(merchant, customer, uid, uid_type, received_msg, channel)
    begin
      return if received_msg.text.blank?

      # tested
      puts 'in function'
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) }
      
      # tested
      @received_msg.text = @received_msg.text.strip
      @amt_ary = check_for_payment
      # is_old_format = (@amt_ary[0] && @amt_ary[1] == "$")

      # scenarios
      # 1. invalid payment intent -> invalid amount and valid sign
      # 2. Amount is outside limit
      # 3. valid payment intent or tag present -> proceed -> handle registered/unregistered user
      # 4. non payment message from an unregistered user
      # 5. otherwise just a regular text from a registered user

      if !@amt_ary[0] && @amt_ary[1].present?  #tested
        puts 'invalid payment intent'
        send_response('We noticed you tried to send a payment. Please resend it in this format: +Amount followed by item name. Ex. +5 Pizza.') 
        return
      end

      @tag = Hashtag.where('user_id = ? and lower(tag) = ? and status = 1', @merchant.id, @tag.downcase).first if @tag.present?
      puts "putting tag if any"
      puts @tag.inspect

      @is_valid_payment_intent = @amt_ary[0] && @amt_ary[1].present?
      if @is_valid_payment_intent && !is_amount_under_limit?    #tested
      elsif @is_valid_payment_intent || @tag                    # tested

        if @tag && @tag.non_payment_tag? && !@is_valid_payment_intent
          puts 'in just tag sent'
          send_response(@tag.response, get_tag_images)
          return
        end
        
        @amt_ary = parse_amount_and_tag
        puts 'from parse amount and tag'
        puts @amt_ary.inspect
        return if @amt_ary.blank?          # No further action needed.

        @amt_ary = parse_user
        puts 'from parse user'
        puts @amt_ary.inspect
       
        return if @amt_ary.blank?          # No further action needed.

        # test for active accounts, they are now active by default.
        if @merchant.fraudulent?                     # tested
          send_response("This #{Rails.application.secrets.app['url']} account cannot receive payments.")
        elsif @merchant.inactive?                    # tested
          puts 'merchant isnt active'
          # EmailingService.email_merchant_the_message
          send_response("This #{Rails.application.secrets.app['url']} phone number is currently unavailable. Please contact us via this email address #{@merchant.email}.")
        elsif merchant_supports_payment?
          puts 'merchant supports payment'
          process_payment
        end
       
        #send_deprecation_warning if is_old_format
      elsif @customer.blank?            
        is_signup = is_signup?
        if is_signup                # tested
          merchant_name = @merchant.org_name.present? ? @merchant.org_name : Rails.application.secrets.app['name']
          merchant_name_prompt = merchant.org_name.present? ? "to " + merchant.org_name : "through #{Rails.application.secrets.app['name']}"
          url = Rails.application.secrets.app["url"]
          short_link = 'test' #UrlShortenerService.shorten_link("#{url}/signup?num=#{@received_msg.from}&referrer_uid=#{@merchant.relay_uid}&referrer=#{merchant_name}")
          send_response("Hi there! You're really close to sending a payment #{merchant_name_prompt} via text. Follow the link to get set up: #{short_link}")
        elsif @channel == 'Message' && get_conversation_refs_count < 2 && !is_signup  # tested
          first_name_str = (@merchant.first_name.present?) ? "my name is #{@merchant.first_name}, " : ''
          custom_welcome = "Hi there, " + first_name_str + "how can I assist you today? If you're looking to send a payment, simply reply with the amount. Ex. +10 #pizza"
          custom_welcome = @merchant.custom_welcome unless @merchant.custom_welcome.blank?
          send_response(custom_welcome)
        end 
      elsif @customer.present? && is_signup?                     # tested
        re = @customer.has_valid_card?
        if re[:valid]
          send_response("You are all set up, just text the amount and description to complete your payment. Ex: $20 for #pizza.")
        else
          # change url
          if re[:type] == 'no_source'
            send_response("To complete your payment by text, please sign in here to add your card information: https://www.getrhombus.com/signin")
          elsif re[:type] == 'expired_source'
            send_response("You are all set up but your payment card has expired. Please sign in here to update your card information: https://www.withrelay.com/signin")
          end
        end     
      else # tested
        puts 'just chatter'
      end

    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In process_message" })
    end
  end

  private

  # tested
  def get_conversation_refs_count
    conv = Conversation.find_by(merchant_id: @merchant.id, uid_type: @uid_type, uid: @uid)
    conv.present? ? ConversationRef.where(conversation_id: conv.id, source: ConversationRef.sources[:customer]).count : 0
  end

  # tested
  # check if text is a payment
  # two forms of payments are currently supported. Ex: $20 fee. Ex. fee +20.
  def check_for_payment
    amt_dollar_ary = is_payment_dollar?
    amt_plus_array = is_payment_plus?

    puts 'in check for payment'
    puts amt_dollar_ary.inspect
    puts amt_plus_array.inspect

    # if user sends in a valid payment or made a mistake by sending $ sign with invalid number
    # $ sign payments have higher priority
    # if they are both false, user is either not paying with format $20 or not trying to make a payment at all
    (amt_dollar_ary[0] || amt_dollar_ary[1].present?) ? amt_dollar_ary : amt_plus_array
  end
  
  # tested
  # check for payment with this format. Ex: $20 fee
  def is_payment_dollar?
    amount = @received_msg.text.split(" ", 2).first[1..-1]
    dollar = @received_msg.text.chr == "$" ? "$" : false
    return to_cents(amount), dollar if is_number?(amount) && dollar.present?
    # return false since this means amount is invalid or dollar wasn't present
    return false, dollar
  end

  # tested
  def is_number?(var)
    Float(var) rescue nil
  end

  # tested
  def to_cents(var)
    Toolbox::Decimal.to_cents(var)
  end

  # tested
  def to_int_or_2dp(var)
    Toolbox::Decimal.to_int_or_2dp(var)
  end

  # tested
  # scan for hashtag and + sign and amt.
  # amt could be invalid, so still track if + was present so user can be notified of payment format.
  def is_payment_plus?
    amt = false
    @tag = false
    plus_present = false
    
    @received_msg.text.scan(/[+#]\S+/).each do |i|
      if i[0] == "+" && !amt
        plus_present = "+"
        amt = to_cents(i[1..-1]) if is_number?(i[1..-1])
      elsif i[0] == "#" && !@tag
        @tag = i
      end
      break if amt && @tag
    end
    
    return amt, plus_present
  end

  # tested
  def is_amount_under_limit?              
    return true if @amt_ary[0] >= 100 && @amt_ary[0] <= 1500000
    puts 'above limits'
    send_response("Please send an amount between 1 dollar and 15,000 dollars. Thanks!")
    false
  end

  # tested
  def parse_amount_and_tag
    if @tag.blank?                                                      # tested
      # if valid payment, charge amt user texted
      @is_valid_payment_intent ? [@amt_ary[0], "no_tag"] : []
    else   
      @received_msg.update(hashtag_id: @tag.id)                       # update message with tag
      if @tag.non_payment_tag?                                        # tested
        puts 'not payment tag'
        @is_valid_payment_intent ? [@amt_ary[0], "no_tag_amt"] : []
      elsif
        @tag_amt = to_cents(@tag.amount)
        puts 'this is tag amount'
        puts @tag_amt 
        if @is_valid_payment_intent               # tested
          @original_amt = @amt_ary[0]
          puts 'this is original amount'
          puts @original_amt
          return [@amt_ary[0], "override_tag_amt"] if @tag.allow_customers_to_override_amount? 
          @tag.always_charge_amount? && @tag_amt == @original_amt ? [@tag_amt, "charge_tag_default"] : [@tag_amt, "cant_override_tag_amt"] 
        else                                      # tested
          puts 'last resort'
          @original_amt = @tag_amt
          [@tag_amt, "charge_tag_default"]  # no amt specified, charge tag amount
        end
      end
    end
  end

  # tested
  def parse_user
    if @customer.present?  
      re = @customer.has_valid_card?
      puts 'has valid card object'
      puts re.inspect
      if !re[:valid]                            #tested
        puts 'no card on file or card has expired'
        if @amt_ary[1] == "cant_override_tag_amt"
          cant_override_tag_amt_message
        else
          # notify user and send sign in link with payment capture
          send_response("Sorry we couldn't process your payment because: #{re[:text]}. Please follow this link xyz.com to add a card to your profile.")
        end
      elsif @amt_ary[1] == "cant_override_tag_amt"            # tested
        puts 'user but cant override_tag_amt'
        cant_override_tag_amt_message
      else                                                 # tested
        puts 'has card and is present'
        return @amt_ary
      end
    else      
      # payment based messages
      if @amt_ary[1] == "cant_override_tag_amt"             # tested
        puts 'no user and cant_override_tag_amt'
        cant_override_tag_amt_message
      else                                                    # tested
        puts 'no user and can override_tag_amt or charge tag default'
        send_response("Sorry we couldn't process your payment. Please follow this link xyz.com to create an account and add a card to your profile.")          
      end
    end
    []
  end

  # notify user of cant_override_tag_amt 
  def cant_override_tag_amt_message
    send_response("#{@tag.tag} will charge $#{to_int_or_2dp(@tag.amount)}. If you'd like to complete this payment, please resend only the hashtag.")    
  end

  # tested
  def is_signup?
    words = ['signup', 'sign-up', 'give', 'pay', 'buy', 'donate', '"give"', '"pay"', "'pay'", "'give'", "'donate'", '"donate"', 'checkout']
    return true if words.include? @received_msg.text.downcase.gsub(/\s+/, "")
    return false
  end

  #def send_deprecation_warning
    #send_response("Relay tips: We've improved your payment experience with Relay by replacing the $ sign with a + tag. You can now text +10 instead of $10 to make a payment to a local business or non-profit.")
    #send_response('Relay tips: With the + tag, you can now place the amount anywhere in the message. Ex. "pizza & broccoli +8 yay!" instead of "$8 pizza & broccoli')
    #send_response("Relay tips: Hashtags are awesome! You can now use hashtags to specify the item you're paying for or the campaign you're donating towards. Ex. +5 #pizza or +20 #ReliefFund. This helps the organization know exactly what you are paying for.")
  #end

  # tested
  def merchant_supports_payment?
    return true if @merchant.can_accept_payments?
    send_response("Sorry we currently can't accept payments via text. A member of our team will contact you shortly to assist you.")
    # EmailingService.missed_payment
    false
  end

  def process_payment
#=begin
    #if not_repeating_payment?
      if @tag.present? && @tag.recurring_payment_tag?
        res = handle_subscription_through_text
        if res.first
          send_response(@tag.response, get_tag_images)
          # send email here or through subscription instance
        else
          send_response(res.second || subscription_error_text)
        end
      else     # tested   
        @new_txn = Transaction.new        
        if @new_txn.process_payment(@amt_ary[0], @merchant, @customer, @received_msg.text, @tag, @channel, true).first
          @received_msg.update_column(:transaction_id, @new_txn.id)
          send_payment_responses
        end
      end
    #end
#=end
  end

  def get_first_name
    @customer.first_name.present? ? " " + @customer.first_name : ''
  end

  def subscription_error_text
    "Hi#{get_first_name}, we were unable to set up your subscription for #{@tag.tag}. A member of our team will get back to you." 
  end

  def get_tag_images
    @tag.images.map { |i| i.avatar.url }
  end

  # tested
  def send_payment_responses
    if @tag.present?
      @new_txn.send_payment_responses(@tag.response, get_tag_images)
    else
      puts '00-9asdddddddddddddd0d9a-09'
      msg_to_send = "Thanks#{get_first_name}. A payment of #{@new_txn.txn_amount} (#{@new_txn.currency}) "
      msg_to_send += (@merchant.tax_percent.to_f == 0.0 ? "was sent to #{@merchant.org_name}." : "plus taxes and fees set by #{@merchant.org_name} was sent.")
      @new_txn.send_payment_responses(msg_to_send)
    end    
  end
  
  # tested  
  def not_repeating_payment?
    # if necessary, you could modify the query to return a text sent to a specific merchant..so add user_id_to
    # the last message contains the current message, so remove from results
    last_messages = @channel.constantize.where("user_id = ? and created_at >= ?", @customer.id, Time.current - 5.minutes).order(created_at: :desc)[1..-1]
    return true if last_messages.nil?
    
    last_messages.each { |m| return false if m.text.strip == @received_msg.text }
    true
  end

  def send_sign_up_link
    short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?amt=#{amt_ary[0]}&num=#{@received_msg.from}
                                      &referrer_uid=#{@merchant.relay_uid}&referrer=#{@merchant.org_name}&msg_id=#{@received_msg.id}")
    send_response("Hi there, thanks for reaching out...to send a payment, sign up here. Thanks! => #{short_link}")
  end  

  # tested
  def send_response(msg, media = [])
    Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, @customer, @uid_type, @uid, msg, @channel, media)
  end

  def handle_subscription_through_text
    begin
      merchant_plan = @tag.merchant_plan
      if merchant_plan.present?                                 
        # if can override amount and amt isnt the same, create plan and create subscription
        if @tag.allow_customers_to_override_amount? && @original_amt != @tag_amt      
          customer_plan = merchant_plan.dup
          customer_plan.amount = @original_amt
          customer_plan.customer_id = @customer.id
          customer_plan.name = generate_resource_name("Plan")
          if customer_plan.create_plan({ team: @merchant })
            create_text_subscription(customer_plan.id)
          else
            customer_plan.destroy                             # revoke created plan on error
            [false]
          end  
        else   # else find the existing plan for tag and create subscription                                                   
          create_text_subscription(merchant_plan.id)
        end
      else
        [false, "Hi#{get_first_name}, #{@tag.tag} is no longer available for subscription."]        
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In handle_subscription_through_text" })
      [false]
    end
  end

  def create_text_subscription(plan_id)
    begin
      merchant_customer = MerchantCustomer.find_by(merchant_id: @merchant.id, customer_id: @customer.id)
      if merchant_customer.present?
        subscription = Subscription.new(plan_id: plan_id, merchant_customer_id: merchant_customer.id, quantity: 1)
        res = subscription.create_subscription({ team: @merchant })
        if res.first
          [true]
        else
          subscription.destroy          
          if res.second == 'card_error' 
            res_text = "Hi#{get_first_name}, your subscription to #{@tag.tag} failed because: #{res.third}. Please sign in here to update your card information: https://www.withrelay.com/signin"
          end
          [false, res_text] 
        end
      else
        # email team
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In create_text_subscription" })
      [false]
    end
  end

end