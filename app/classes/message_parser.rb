class MessageParser

  ## TEST captured link for sign in

  include Transactionable

  # Message/FbMessage object must exist when calling this method
  # from can be user fb cred or phone number
  # customer can be nil
  def process_message(merchant, customer, from, received_msg, channel)
    begin
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) }
      
      @amt_ary = check_for_payment
      is_old_format? = @amt_ary[0] && @amt_ary[1] == "$"

      # scenarios
      # 1. invalid payment intent -> invalid amount and valid sign
      # 2. Amount is outside limit
      # 3. valid payment intent -> proceed -> handle registered/unregistered user
      # 4. non payment message from an unregistered user
      # 5. otherwise just a regular text from a registered user

      if !@amt_ary[0] && @amt_ary[1].present?
        send_response('We noticed you tried to send a payment. Please resend it in this format. Ex. +5 #CheeseBurgers')
      elsif @amt_ary[0] && @amt_ary[1].present? && !is_amount_under_limit?              
      elsif @amt_ary[0] && @amt_ary[1].present?             

        @tag = Hashtag.where('user_id = ? and lower(tag) = ?', @merchant.id, @tag.downcase).first if @tag.present?
        @amt_ary = parse_amount_and_tag
        @amt_ary = parse_user
       
        return if @amt_ary.blank?          # No further action needed
        
        # test for active accounts, they are now active by default.
        unless @merchant.is_active
          # send_response
        elsif merchant_supports_payment?
          process_payment
        end
       
        send_deprecation_warning if is_old_format? 

      elsif @customer.blank?

        # FbMessage/Messenger doesn't support signup links, only signin link...see method in messenger service class
        # Check with Edwin on what to do for Messenger users
        if @channel == "Message"
          if is_signup = is_signup?
            merchant_name = @merchant.org_name.present? ? @merchant.org_name : "Rhombus"
            short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?num=#{@received_msg.from}&referrer_id=#{@merchant.id}&referrer=#{merchant_name}")
            send_response("To chat with us or send a payment, sign up here: #{short_link}")
          elsif Message.where(from: @received_msg.from, to: @received_msg.to).limit(2).count < 2 && !is_signup
            # merchant name is now through person
            merchant_rep = @merchant.people.where(role: 0).first
            first_name = (merchant_rep.present?) ? "my name is #{merchant_rep.first_name}, " : ''
            custom_welcome = "Hi there, " + first_name + "how can I assist you today? If you're looking to send a payment, simply reply with the amount. Ex. +10 #donut"
            custom_welcome = @merchant.custom_welcome unless @merchant.custom_welcome.blank?
            send_response(custom_welcome)
          end
        end
      end
    rescue StandardError => e
      # notify team
      puts e.message
    end
  end

  private

  # check if text is a payment
  # two forms of payments are currently supported. Ex: $20 fee. Ex. fee +20.
  def check_for_payment
    amt_dollar_ary = is_payment_dollar?
    amt_plus_array = is_payment_plus?

    # if user sends in a valid payment or made a mistake by sending $ sign with invalid number
    # $ sign payments have higher priority
    # if they are both false, user is either not paying with format $20 or not trying to make a payment at all
    (amt_dollar_ary[0] || amt_dollar_ary[1].present?) ? amt_dollar_ary : amt_plus_array
  end
  
  # check for payment with this format. Ex: $20 fee
  def is_payment_dollar?
    amount = @received_msg.text.split(" ", 2).first[1..-1]
    dollar = @received_msg.text.chr == "$" ? "$" : false
    return to_cents(amount), dollar if is_number?(amount) && dollar.present?
    return false, dollar
  end

  def is_number?(var)
    begin
      true if Float(var)
    rescue StandardError => err
      false
    end
  end

  def to_cents(var)
    ((var.to_f.abs)*100).round        # 100 * 1.1
  end

  # scan for hashtag and + sign and amt.
  # amt could be invalid, so still track if + was present so user can be notified of payment format.
  def is_payment_plus?
    t = @received_msg.text.scan(/[+#]\S+/)
    amt = false
    @tag = false
    plus_present = false
    
    t.each do |i|
      if i[0] == "+" && !amt
        plus_present = "+"
        amt = to_cents(i[1..-1]) if is_number?(i[1..-1])
      elsif i[0] == "#" && !@tag
        @tag = i
      end
      break if amt && @tag
    end
    
    amt, plus_present
  end

  def is_amount_under_limit?
    return true if @amt_ary[0] <= 1500000
    # notify user and send to merchant dashboard
    send_response("Sorry, we are unable to make payments above 15,000 dollars. But you can send in smaller amounts. Thanks!")
    # notify merchant via Email?
    false
  end

  def parse_amount_and_tag
    if @tag.blank?                                       
      [@amt_ary[0], "no_tag"]                             # so charge amt user texted
    else      
      if @tag.non_payment_tag?                                               
        [@amt_ary[0], "no_tag_amt"]                       # so charge amt user texted
      else
        @tag_amt = to_cents(Toolbox::Decimal.to_2dp(@tag.amount))
        @original_amt = @amt_ary[0]
        [@amt_ary[0], "override_tag_amt"]
        # cant override amount if tag doesnt allow it and customer amount isnt equal to tag amount
        [@tag.amount, "cant_override_tag_amt"] if !@tag.allow_customers_to_override_amount && @tag_amt != @original_amt
      end
    end
  end

  def parse_user
    if @customer.present?
      if !@customer.card_token
        # notify user and send to merchant dashboard
        # send_response notify and send sign in link with payment capture
        # payment capture notice if cant ovveride_tag_amt
      elsif @amt_ary[1] == "cant_override_tag_amt"    # @tag.present? && !@tag.allow_customers_to_override_amount?
        # notify user and send to merchant dashboard
        send_response notify of cant_override_tag_amt 
      else
        return @amt_ary
      end
    else      
      # payment based messages
      if @amt_ary[1] == "cant_override_tag_amt"       # @tag.present? && !@tag.allow_customers_to_override_amount?
        send_sign_up_link with ovveride message
      else
        send_sign_up_link without ovveride message
      end
    end
    []
  end

  def is_signup?
    words = ['signup', 'sign-up', 'give', 'pay', 'buy', 'donate']
    return true if words.include? @received_msg.text.downcase.gsub(/\s+/, "")
    return false
  end

  def send_deprecation_warning
    send_response("We're improving your payment experience on Rhombus by replacing the $ sign with a + tag. Ex. You can now text +10 instead of $10.")
    send_response('With the + tag, you can now place the amount anywhere in the message. Ex. "cheese burgers +8 yay!", instead of "$8 cheese burgers')
    send_response("Btw, hashtags are awesome! You can now use hashtags to specify the item you're paying for or the campaign you're donating towards. Ex. +5 #CheeseBurgers")
    send_response("This helps your local business know exactly what you are paying for!")
  end

  def merchant_supports_payment?
    return true if @merchant.can_accept_payments?
    # notify user and send to merchant dashboard
    # send_response("Thank you for sending a payment with Rhombus, but the merchant hasn't completed the account to receive payments.")
    # notify merchant via Email?    false
  end

  def process_payment
    if not_repeating_payment?
      if @tag.present? && @tag.recurring_payment_tag?
        res = handle_subscription_through_text
        if res.first
          # send response
        else
          # send response
        end
      else        
        @new_txn = Transaction.new
        @new_txn.process_payment(@amt_ary[0], @merchant, @customer, @received_msg.text, (@tag ? @tag.id : nil), @channel, true)
        if @new_txn.id.present?
          @received_msg.update(transaction_id: @new_txn.id)
          send_payment_responses        
        end
      end
    end
  end

  def send_payment_responses
    first_name = (@user.card_name.present?) ? " " + @user.card_name.split.first : ''
    msg_to_send = "Thanks" + first_name + ". A payment of #{amt_in_decimal(@stripe_res.amount)} (#{@stripe_res.currency}) "
    msg_to_send = msg_to_send + (@merchant.tax_percent == "0" ? "was sent to #{@merchant.org_name}." : "plus taxes and fees set by #{@merchant.org_name} was sent."
    
    if @tag.present?
      msg = "sdasdsa"
    else
      msg = "dsadsadas"
    end

    @new_txn.send_text_receipt(msg_to_send)
    @new_txn.send_email_receipt
  end
    
  def not_repeating_payment?
    # if necessary, you could modify the query to return a text sent to a specific merchant..so add user_id_to
    # the last message contains the current message, so remove from results
    last_messages = @channel.constantize.where("user_id = ? and created_at >= ?", @customer.id, Time.current.utc - 5.minutes).order(created_at: :desc)[1..-1]
    return true if last_messages.nil?
    
    last_messages.each do |m|
      return false if m.text.strip == @received_msg.text
    end
    true
  end

  def send_sign_up_link
    short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?amt=#{amt_ary[0]}&num=#{@received_msg.from}
                                      &referrer_id=#{@merchant.id}&referrer=#{@merchant.org_name}&msg_id=#{@received_msg.id}")
    send_response("Hi there, thanks for reaching out...to send a payment, sign up here. Thanks! => #{short_link}")
  end

  def send_response(msg)    
    if @channel == 'Message'
      message = Message.new
      message.send_and_save_message(@merchant.rhombus_number, @received_msg.from, msg)
    elsif @channel == "FbMessage"

    end

    # needs to handle messenger here
    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(@received_msg.from, @merchant.rhombus_number, msg, message.created_at, true) if message
  end

  def handle_subscription_through_text
    # if can override amount and amt isnt the same, create plan and create subscription
    # else find the existing plan for tag and create subscription
    begin
      merchant_plan = @tag.plan
      if merchant_plan.present?
        if @tag.allow_customers_to_override_amount? && @original_amt != @tag_amt      
          customer_plan = merchant_plan.dup
          customer_plan.amount = @original_amt
          customer_plan.customer_id = @customer.id
          customer_plan.name = generate_resource_name("Plan")
          if customer_plan.create_plan({ team: @merchant })
            create_text_subscription(customer_plan.id)
          else
            customer_plan.destroy     # revoke created plan on error
            [false, "Unable to create subscription"]
          end  
        else 
          create_text_subscription(merchant_plan.id)
        end
      else
        [false, "Unable to subscribe, plan no longer exists."]
      end
    rescue StandardError => e
      [false, "Unable to create subscription"]
    end
  end

  def create_text_subscription(plan_id)
    merchant_customer = MerchantCustomer.find_by(merchant_id: @merchant.id, customer_id: @customer.id)
    if merchant_customer.present?
      subscription = Subscription.new(plan_id: plan_id, merchant_customer_id: merchant_customer.id, quantity: 1)
      res = subscription.create_subscription({ team: current_user })
      if res.first
        return [true, 'Subscription created successfully']
      else
        subscription.destroy
        return [false, res.third] if res.second == 'card_error' 
      end
    end
    [false, 'Something went wrong']      
  end


end