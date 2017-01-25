class Transaction < ActiveRecord::Base

  include Transactionable
  include CSVHandler

  has_one :message
  has_one :refund
  has_many :notification_logs, as: :notifiable, dependent: :destroy

  belongs_to :hashtag
  belongs_to :merchant_customer
  belongs_to :user, counter_cache: true
  belongs_to :team, class_name: "User", counter_cache: true
 
  # send in a hash instead to PaymentService?
  def process_payment(amt, merchant, user, msg, hashtag_id, channel, capture=true) 
    begin  
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) }

      tax_percent = (((@merchant.tax_percent.to_f) / 100) + 1)                                            # default is 0

      @amt_with_taxes = (@amt.to_f * tax_percent).round                                                   # total amount to charge 
      @app_fee = ((Rails.application.secrets.app_fee_percent.to_f / 100) * @amt_with_taxes).round         # app fee
      amt_less_stripe_fee = ((@amt_with_taxes * 0.975) - 30.0).round                                      # 2.5% + 30c
      
      @stripe_res_ary = PaymentService.charge(@amt_with_taxes, amt_less_stripe_fee, @app_fee, merchant, user, msg, capture)
      @stripe_res = @stripe_res_ary[0]

      if @stripe_res
        update_transaction_data
        [true, "Transaction done"]
      else
        # true if it is a card decline...we text only customers. Merchants may not have textable number on file.
        send_card_error_text if @stripe_res_ary[3] && user.is_customer?     
        send_payment_failure_email(@stripe_res_ary[1], @stripe_res_ary[3])
        [false, @stripe_res_ary[2]]
      end     
    rescue StandardError => err
      send_payment_failure_email(err, false)
      [false, "Something went wrong"]
    end
  end

  def update_transaction_data
    _stripe_fee = @amount_with_taxes - amt_less_stripe_fee

    self.update(amount: amt_in_decimal(@amt), amount_with_taxes: amt_in_decimal(@stripe_res.amount), 
                application_fee: amt_in_decimal(@app_fee), stripe_fee: _stripe_fee,
                currency: @stripe_res.currency, txn_uri: @stripe_res.id, txn_number: generate_txn_number,
                status: @stripe_res.status, txn_available_at: @stripe_res.created, last4: @stripe_res.source.last4, 
                card_name: @stripe_res.source.name, tax_percent: @merchant.tax_percent, destination: @stripe_res.destination, 
                team_id: @merchant.id, user_id: @user.id, notes: @msg, hashtag_id: @hashtag_id, captured: @stripe_res.captured,
                exp_month: @stripe_res.source.exp_month, exp_year: @stripe_res.source.exp_year, card_type: @stripe_res.source.brand,
                description: "Payment to #{@merchant.email}. #{@merchant.org_name}. rhombus number: #{@merchant.rhombus_number}")
  end

  def amt_in_decimal(amt)
    (amt.to_f/100).round(2)
  end

  def big_decimal_2dp(amt)
    Toolbox::Decimal.to_2dp(amt)
  end

  def send_card_error_text
    # change text based on capture or not
    # if @capture

    msg = @channel.constantize.new
    msg.send_and_save_message(@merchant.rn_type, @merchant.rhombus_number, @user.phone_number, "Your payment to #{@merchant.org_name} failed because: #{err[:message]}")
    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(@user.phone_number, @merchant.rhombus_number, msg.text, msg.created_at, true)      
  end

  def send_text_receipt(msg_to_send)    
    msg = @channel.constantize.new
    msg.send_and_save_message(@merchant.rn_type, @merchant.rhombus_number, @user.phone_number, msg_to_send)
    
    # Log sms notification
    self.notification_logs.create(notify_type: 'new_transaction', reason: 'receipt', channel: @channel, channel_id: msg.id)    
    # Send to merchant's messaging channel
    RealtimeStreamService.send_message_via_number(@user.phone_number, @merchant.rhombus_number, msg.text, msg.created_at, true)
  end

  def send_email_receipt
    # Also need to email merchant here too
    EmailingService.send_receipt(merchant_email: @merchant.email, to: @user.email, merchant_name: @merchant.org_name, transaction_number: self.txn_number, 
                                  text: self.notes, transaction_date: self.created_at, amount: big_decimal_2dp(self.amount), 
                                  amt_with_taxes: big_decimal_2dp(self.amount_with_taxes), org_phone: @merchant.org_phone, currency: @stripe_res.currency)
    # Log email notification
    self.notification_logs.create(notify_type: 'new_transaction', reason: 'receipt', channel: 'Email')
  end

  def send_payment_failure_email(err, to_merchant)
    # change text based on capture or not
    # if @capture
    
    EmailingService.charge_failure_notification(to: @merchant.email, customer_email: @user.email, customer_phone: @user.phone_number, card_name: @user.card_name, 
                                                  last4: @user.last4, text: @msg, org_phone: @merchant.org_phone, rhombus_number: @merchant.rhombus_number, 
                                                  dump: err, to_merchant: to_merchant)
  end

  def process_dashboard_txn(amt, merchant, user, msg, hashtag_id, channel="Message", capture=true)
    process_payment(amt, merchant, user, msg, hashtag_id, channel, capture) 
    capture ? handle_captured_txn : handle_uncaptured_txn
  end

  def handle_captured_txn
    begin  
      unless @stripe_res
        # notify platform...should we email merchant too? could be a security measure.
        [false, "Payment successful"]
      else
        send_text_receipt
        send_email_receipt  
        [true, 'Unable to process txn because: ' + @stripe_res_ary[2]]
      end   
    rescue StandardError => err
      # notify platform...should we email merchant too? could be a security measure.
      [false, "Something went wrong"]
    end
  end

  def handle_uncaptured_txn
    begin  
      unless @stripe_res
        # notify platform...should we email merchant too? could be a security measure.
        [false, "can't authorize card"]
      else
        #send_text_receipt
        send_email_receipt  
        [true, 'card is authorized']
      end   
    rescue StandardError => err
      # notify platform...should we email merchant too? could be a security measure.
      [false, "Something went wrong"]
    end
  end

  # https://support.stripe.com/questions/does-stripe-support-authorize-and-capture
  def capture_uncaptured_txn(merchant, user, charge_id, channel="Message")
    begin
      @capture = true
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) if arg != :charge_id }
      payment_ary = PaymentService.process_captured_charge(charge_id)
      if payment_ary[0]
        # will capture change transaction status and date???
        self.update(captured: true)
        send_text_receipt("adasdsa")
        send_email_receipt
        [true, "Payment processed"]
      else
        # notify platform only. Merchants don't need an email for this.
        # payment_ary[1]
        [false, payment_ary[2]]  
      end   
    rescue StandardError => err
      # notify platform only. Merchants don't need an email for this.
      [false, "Something went wrong"]
    end
  end

end

