class MessageParserClass

  class << self


    # must have identified existing team, customer and message isnt blank
    # and saved incoming message

    # How to differentiate messenger and sms?

    def process_message(team, customer, message)
      begin
        
        @msg_text = message.strip

        @amt_ary = check_for_payment
        is_old_format = @amt_ary[0] && @amt_ary[1] == "$"

        


      rescue => e
      end
    end


    private

    # Check if text is a payment
    # Two forms of payments are currently supported. Ex: $20 fee. Ex. fee +20.
    def check_for_payment
      amt_dollar_ary = is_payment_dollar?
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
      amount = @msg_text.split(" ", 2).first[1..-1]
      dollar_present = @msg_text.chr == "$" ? "$" : false
      return to_cents(amount), dollar_present if is_number?(amount) && dollar_present.present?
      return false, dollar_present
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








  end

end