class MessageParser

  # How to differentiate messenger and sms?
  ## TEST captured link for sign in

  def process_message(team, customer, message, msg_id, channel)
    begin
      
      @msg_id = msg_id # message object is better here
      @msg_text = message.strip
      @channel = channel

      @amt_ary = check_for_payment
      is_old_format? = @amt_ary[0] && @amt_ary[1] == "$"

      # change params...see function params...use initializer?
      # or just pass in the user objects
      @customer = User.find_by(phone_number: params[:From])
      @merchant = User.find_by(rhombus_number: params[:To])

      # scenarios
      # 1. invalid payment intent -> invalid amount and valid sign
      # 2. Amount is outside limit
      # 3. valid payment intent -> proceed
      # 4. otherwise just a regular text
      # 5. non payment message from an unregistered user

      if !@amt_ary[0] && @amt_ary[1].present?
        send_response('We noticed you tried to send a payment. Please resend it in this format. Ex. +5 #CheeseBurgers')
      elsif @amt_ary[0] && @amt_ary[1].present? && !is_amount_under_limit?              
      elsif @amt_ary[0] && @amt_ary[1].present?             

        @tag = Hashtag.where('user_id = ? and lower(tag) = ?', @merchant.id, @tag.downcase).first : nil
        @amt_ary = parse_amount_and_tag
        @amt_ary = parse_user
       
        return if @amt_ary.empty?          # No further action needed
        
        # test for active accounts, they are now active by default.
        if !@merchant.is_active?
          # send_response
        elsif merchant_supports_payment?
          process_payment
        else
          # notify user and send to merchant dashboard
          # send_response("Thank you for sending a payment with Rhombus, but the merchant hasn't completed the account to receive payments.")
          # notify merchant via Email?
        end
       
        send_deprecation_warning if is_old_format?
      
      elsif @customer.empty?               
      
        merchant_name = @merchant.org_name.present? ? @merchant.org_name : "Rhombus"

        # params From only if SMS...need to support FbMessages too
        if is_signup = is_signup?
          short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?num=#{params[:From]}&referrer_id=#{@this_merchant.id}&referrer=#{merchant_name}")
          send_response("To chat with us or send a payment, sign up here: #{short_link}")
        end

        # This needs to support FbMessages too
        if Message.where(from: params[:From], to: params[:To]).limit(2).count < 2 && !is_signup
          # merchant name is now through person
          merchant_rep = @merchant.people.where(role: 0).first
          first_name = (merchant_rep.present?) ? "my name is #{merchant_rep.first_name}, " : ''
          custom_welcome = "Hi there, " + first_name + "how can I assist you today? If you're looking to send a payment, simply reply with the amount. Ex. +10 #donut"
          custom_welcome = @merchant.custom_welcome unless @merchant.custom_welcome.blank?
          send_response(custom_welcome)
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
    amount = @msg_text.split(" ", 2).first[1..-1]
    dollar = @msg_text.chr == "$" ? "$" : false
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
    t = @msg_text.scan(/[+#]\S+/)
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
    if @tag.empty?                                        # tag doesnt exists
      [@amt_ary[0], "no_tag"]                             # so charge amt user texted, set parse/outcome type, tag id, tag name
    elsif @tag.present?      
      if @tag.non_payment_tag?                                               
        [@amt_ary[0], "no_tag_amt"]                       # so charge amt user texted
      else 
        if @tag.allow_customers_to_override_amount?       # tag default amount isnt enforced
          [@amt_ary[0], "override_tag_amt"]               # else charge amount user sent
        else 
          [@tag.amount, "cant_override_tag_amt"]
        end
      end
    end
  end

  def parse_user
    if @customer.present?
      if !@customer.card_token
        # notify user and send to merchant dashboard
        # send_response notify and send sign in link with payment capture
        # payment capture notice if cant ovveride_tag_amt
        []
      elsif @amt_ary[1] == "cant_override_tag_amt"
        # notify user and send to merchant dashboard
        send_response notify of cant_override_tag_amt 
        []       
      else
        @amt_ary
      end
    else      
      # payment based messages
      if @amt_ary[1] == "cant_override_tag_amt"
        send_sign_up_link with ovveride message
      else
        send_sign_up_link without ovveride message
      end
      []
    end
  end

  def is_signup?
    words = ['signup', 'sign-up', 'give', 'pay', 'buy', 'donate']
    return true if words.include? @msg_text.downcase.gsub(/\s+/, "")
    return false
  end

  def send_deprecation_warning
    send_response("We're improving your payment experience on Rhombus by replacing the $ sign with a + tag. Ex. You can now text +10 instead of $10.")
    send_response('With the + tag, you can now place the amount anywhere in the message. Ex. "cheese burgers +8 yay!", instead of "$8 cheese burgers')
    send_response("Btw, hashtags are awesome! You can now use hashtags to specify the item you're paying for or the campaign you're donating towards. Ex. +5 #CheeseBurgers")
    send_response("This helps your local business know exactly what you are paying for!")
  end

  def merchant_supports_payment?

  end

  def process_payment
    if not_repeating_payment?
      # scope this to number
      customer_txn_id = Transaction.charge_customer_card(@amt_ary, @this_merchant, @this_user, @msg_text)
      @saved_msg.update(transaction_id: customer_txn_id) if @saved_msg && @saved_msg.id.present?   # Save transaction id
    end
  end

  def not_repeating_payment?
    # if necessary, you could modify the query to return a text sent to a specific merchant..so add user_id_to
    last_messages = Message.where("user_id = ? and created_at >= ?", @this_user.id, Time.current.utc - 5.minutes).order(created_at: :desc)[1..-1]
    return true if last_messages == nil
    last_messages.each do |m|
      return false if m.text.strip == @msg_text
    end
    return true
  end

  def send_sign_up_link
    short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?amt=#{amt_ary[0]}&num=#{params[:msisdn]}
                                      &referrer_id=#{@this_merchant.id}&referrer=#{@this_merchant.org_name}&msg_id=#{@saved_msg.id}")
    send_response("Hi there, thanks for reaching out...to send a payment, sign up here. Thanks! => #{short_link}")
  end

  def send_response(msg)
    
    if @channel == 'sms'
      message = Message.send_and_save_message(params[:To], params[:From], msg)
    elsif @channel == "messenger"

    end

    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(params[:From], params[:To], msg, message.created_at, true) if message
  end

end