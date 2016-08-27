module ParseText
  extend ActiveSupport::Concern

  ## help need to handle media url here                      
  ## help change how i test if merchant can take payments
  ## help captured link for sign in

  def process_message(params)  
    begin
      return if params[:Body].blank?

      @msg_text = params[:Body].strip
      params[:From] = params[:From][1..-1] if params[:From].chr == "+"
      params[:To] = params[:To][1..-1] if params[:To].chr == "+"  

      save_inbound_text
      
      @amt_ary = check_for_payment
      is_old_format = @amt_ary[0] && @amt_ary[1] == "$"

      #### Handle quick edge cases
      if !@amt_ary[0] && @amt_ary[1]            # Invalid payment intent, invalid amount, valid sign - notify user and move on
        send_response('We noticed you tried to send a payment. Please resend it in this format. Ex. +5 #CheeseBurgers')
        return
      elsif @amt_ary[0] && @amt_ary[1] && !is_amount_under_limit?              # amount is valid but outside limits
        return
      end
      #### Handle quick edge cases

      ## convert to instance variable
      @this_user = User.find_by(phone_number: params[:From])
      @this_merchant = User.find_by(rhombus_number: params[:To])

      @amt_ary = check_for_tag
      @amt_ary = parse_amount_and_tag

      if @amt_ary.empty?
      else
        @amt_ary = parse_user
        if @amt_ary.empty?
        else
          # No test for active accounts, they are now active by default but can be turned on as needed
          if merchant_supports_payment             
            process_payment
          else
            # notify user and send to merchant dashboard            
            # send_response("Thank you for sending a payment with Rhombus, but the merchant hasn't completed the account to receive payments.")
            # notify merchant via Email?
          end
        end
      end
      send_deprecation_warning if is_old_format

    rescue StandardError => err
      logger.error err.message
      err.backtrace.each { |line| logger.error line }
      # notify us something went wrong
    end
  end

  def parse_amount_and_tag
    ## A valid payment intent is when amt and sign are valid/true
    valid_payment_intent = @amt_ary[0] && @amt_ary[1]
    # tag doesnt exists 
    if !@amt_ary[2]
      if !valid_payment_intent                  # and if no payment intent - do nothing
        return []
      elsif valid_payment_intent                # but with payment intent - so charge amt user texted, set parse/outcome type, tag id, tag name
        return [@amt_ary[0], "no_tag", nil, nil]
      end     
    elsif @amt_ary[2]                                         # tag exists 
      if !@amt_ary[4]                                         # but not a payment tag
        if !valid_payment_intent                              # and no payment intent - do nothing
          return []
        elsif valid_payment_intent                            # and a payment intent - so charge amt user texted
          return [@amt_ary[0], "no_tag_amt", @amt_ary[2], @amt_ary[3]]
        end
      elsif @amt_ary[4]                                                             # a payment tag
        if !@amt_ary[5]                                                             # tag default amount isnt enforced
          if !valid_payment_intent                                                  # if no payment intent - charge default amt for tag
            return [@amt_ary[4], "default_tag_amount", @amt_ary[2], @amt_ary[3]]
          elsif valid_payment_intent                                                        # else charge amount user sent
            return [@amt_ary[0], "not_precedent_tag_amt", @amt_ary[2], @amt_ary[3]]
          end
        elsif @amt_ary[5]                                                                 # if tag default amount is enforced
          if !valid_payment_intent                                                        # if no payment intent, charge default amount for tag
            return [@amt_ary[4], "default_tag_amount", @amt_ary[2], @amt_ary[3]]
          elsif valid_payment_intent                                                      # if valid payment, notify user that default amt has to be charged
            return [@amt_ary[4], "precedent_tag_amt", @amt_ary[2], @amt_ary[3]]
          end
        end
      end
    end
  end

  def parse_user
    if @this_user.present? 
      if @amt_ary[1] == "precedent_tag_amt"
        # notify user and send to merchant dashboard
        send_response notify of precedent_tag_amt
        return []
      elsif !@this_user.customer_uri
        # notify user and send to merchant dashboard
        # send_response notify and send sign in link
        return []  
      elsif @this_user.customer_uri
        return @amt_ary
      end
    elsif !@this_user.present? 
      merchant_name = @this_merchant.org_name ? @this_merchant.org_name : "Rhombus"
      # payment based messages
      if @amt_ary[1] == "precedent_tag_amt"
        send_sign_up_link if @saved_message && @saved_message.id.present? 
        return []
      elsif @amt_ary[1] != "precedent_tag_amt"
        send_sign_up_link if @saved_message && @saved_message.id.present?
        return []
      else 
        # not payment related messages

        is_signup = is_signup?
        if is_signup
          short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?num=#{params[:From]}&referrer_num=#{params[:To]}&referrer=#{merchant_name}")
          send_response("To chat with us or send a payment, sign up here: #{short_link}")
        end

        if Message.where(from: params[:From], to: params[:To]).limit(2).count < 2 && !is_signup
          first_name = (@this_merchant.first_name.present?) ? "my name is #{@this_merchant.first_name}, " : ''
          custom_welcome = "Hi there, " + first_name + "how can I assist you today? If you're looking to send a payment, simply reply with the amount. Ex. +10 #donut"
          custom_welcome = @this_merchant.custom_welcome unless @this_merchant.custom_welcome.blank?
          send_response(custom_welcome)
        end   
        return []     
      end
    end
  end

  def send_sign_up_link 
    short_link = UrlShortenerService.shorten_link("https://www.getrhombus.com/signup?amt=#{amt_ary[0]}&num=#{params[:msisdn]}
                                      &referrer_num=#{params[:to]}&referrer=#{@this_merchant.org_name}&msg_id=#{@saved_message.id}")
    send_response("Hi there, thanks for reaching out...to send a payment, sign up here. Thanks! => #{short_link}")
  end

  # Check if text is a payment
  # Two forms of payments are currently supported. Ex: $20 fee. Ex. fee +20.
  def check_for_payment
    amt_ary = is_payment_dollar?
    amount_plus_array = is_payment_plus?

    # make amt_ary look like amount_plus_array
    # if user sends in a valid payment or made a mistake by sending $ sign with invalid number
    # $ sign payments have higher priority
    # if they are both false, user is either not paying with format $20 or not trying to make a payment at all
    if amt_ary[0] || amt_ary[1] 
      amt_ary[2] = amount_plus_array[2]
      return amt_ary
    end
    return amount_plus_array    
  end

  # check for payment with this format. Ex: $20 fee 
  def is_payment_dollar?
    amount = get_number
    dollar_present = @msg_text.chr == "$" ? "$" : false
    return to_cents(amount), dollar_present if is_number?(amount) && dollar_present
    return false, dollar_present
  end

  def get_number
    return (@msg_text.split(" ", 2).first[1..-1])
  end

  def is_number?(var)
    begin
      true if Float(var)
    rescue StandardError => err
      false
    end
  end

  def to_cents(var)
    return ((var.to_f.round(2).abs)*100).round
  end

  # scan for hashtag and + sign and amt. 
  # amt could be invalid, so still track if + was present so user can be notified of payment format. 
  def is_payment_plus?
    t = @msg_text.scan(/[+#]\S+/)
    amt = false
    tag = false
    plus_present = false
    t.each do |i|
      if i[0] == "+" && !amt
        plus_present = "+"
        amt = to_cents(i[1..-1]) if is_number?(i[1..-1])
      elsif i[0] == "#" && !tag
        tag = i
      end
      break if amt && tag
    end
    return amt, plus_present, tag
  end

  def check_for_tag
    tag = nil
    tag = Hashtag.where('user_id = ? and lower(tag) = ?', @this_merchant.id, @amt_ary[2].downcase) if @amt_ary[2]

    tag_id = tag.present? ? tag.id : nil
    tag_tag = tag.present? ? tag.tag : nil
    tag_amount = (tag.present? && tag.amount) ? tag.amount : nil
    tag_precedent = (tag.present? && tag.is_precedent) ? true : false

    return @amt_ary[0], @amt_ary[1], tag_id, tag_tag, tag_amount, tag_precedent
  end

  def send_deprecation_warning
    send_response("We're improving your payment experience on Rhombus by replacing the $ sign with a + tag. Ex. You can now text +10 instead of $10.")
    send_response('With the + tag, you can now place the amount anywhere in the message. Ex. "cheese burgers +8 yay!", instead of "$8 cheese burgers')
    send_response("Btw, hashtags are awesome! You can now use hashtags to specify the item you're paying for or the campaign you're donating towards. Ex. +5 #CheeseBurgers")
    send_response("This helps your local business know exactly what you are paying for!")
  end

  def is_signup?
    words = ['signup', 'sign-up', "#signup", "#sign-up", 'give', "#give", 'pay', "#pay", 'buy', '#buy', 'donate', "#donate"]
    return true if words.include? @msg_text.downcase.gsub(/\s+/, "")  
    return false
  end

  def is_amount_under_limit?
    return true if @amt_ary[0] <= 1500000
    # notify user and send to merchant dashboard
    send_response("Sorry, we are unable to make payments above 15,000 dollars. But you can send in smaller amounts. Thanks!")
    # notify merchant via Email?
    return false
  end

  def process_payment
      if not_repeating_payment?
        customer_txn_id = Transaction.charge_customer_card(@amt_ary, @this_merchant, @this_user, @msg_text)
        @saved_message.update(transaction_id: customer_txn_id) if @saved_message && @saved_message.id.present?   # Save transaction id
      end
  end

  def not_repeating_payment?
    # if necessary, you could modify the query to return a text sent to a specific merchant..so add user_id_to
    last_messages = Message.where("user_id = ? and created_at >= ?", @this_user.id, Time.now.utc - 5.minutes).order(created_at: :desc)[1..-1]
    return true if last_messages == nil
    last_messages.each do |m|
      return false if m.text.strip == @msg_text
    end
    return true
  end

  def send_response(msg)
    message = Message.send_and_save_message(params[:To], params[:From], msg)
    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(params[:From], params[:To], msg, message.created_at, true) if message
  end
 
  def save_inbound_text
    begin  
      # if not for payment, transaction_id = 0 
      @saved_message = Message.save_text(from: params[:From], to: params[:To], messageId: params[:MessageSid], 
                              text: params[:Body], transaction_id: 0)    
    rescue StandardError => err
      @saved_message = nil
    end
    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(params[:From], params[:To], params[:Body], @saved_message.created_at) if @saved_message
    @saved_message
  end

  #send delivery reports for twilio (very incomplete)
  def save_delivery_receipts(params)          
    #begin
    message = Message.find_by(messageId: params[:MessageSid]) 
    #rescue
=begin
      # if somehow the message id doesnt exist
      @message = Message.new
      # @message.save_text(from: query_hash["to"], network_code: query_hash['network-code'], messageId: query_hash['messageId'], 
      #   to: query_hash["msisdn"], status_delivery: query_hash["status"], err_code: query_hash['err-code'], message_price: query_hash["price"], 
      #   scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"], 
      #   client_ref: query_hash['client-ref'], message_code: 8)

      @message.save_text(from: params[:From], messageId: params[:MessageSid], to: params[:To], message_code: 8)
=end
    #else
    if message
      message.save_text(status_delivery: query_hash["status"], err_code: query_hash['err-code'],
        scts: query_hash['scts'], message_timestamp: query_hash["message-timestamp"])
      #end
    end
    #if !query_hash.has_key?("network-code")        # Looks like nexmo doesnt always provide this...not sure
      #query_hash['network-code'] = ""
    #end
  end
end

