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
 
  # Capture can change transaction status and date
  # does this include hashtag_id
  # send in a hash instaed to PaymentService?

  def process_text_payment(amt, merchant, user, msg, tag_id, channel, capture=true) 
    begin    
      @merchant = merchant
      @user = user
      @msg = msg
      @channel = channel
      @hashtag_id = tag_id

      @amt = amt
      tax_percent = (((@merchant.tax_percent.to_f) / 100) + 1)                     # default is 0
      @amt_with_taxes = (@amt.to_f * tax_percent).round      
      @app_fee = ((Rails.application.secrets.app_fee_percent.to_f / 100) * @amt_with_taxes).round

      @stripe_response_array = PaymentService.charge(@amt_with_taxes, merchant, user, msg, capture)
      @stripe_res = @stripe_response_array[0]

      if @stripe_res
        update_transaction_data
      else
        send_card_error_text if @stripe_response_array[2]         # true if it is a card decline...we text the customer about it
        send_charge_failure_notification(@stripe_response_array[1], @stripe_response_array[2])
      end     
    rescue StandardError => err
      send_charge_failure_notification(err, false)
    end
  end

  def update_transaction_data
    # This might need to change if we charge merchants different fees
    amt_less_fees = amt_in_decimal(@amt_with_taxes.to_f - @app_fee.to_f - ((@amt_with_taxes.to_f * 0.029) + 0.3))     # this line first

    self.update(currency: @stripe_res.currency, captured: @stripe_res.captured, application_fee: amt_in_decimal(@app_fee),
                description: "Payment to #{@merchant.email}. #{@merchant.org_name}. rhombus number: #{@merchant.rhombus_number}", 
                txn_uri: @stripe_res.id, amount: amt_in_decimal(@amt), txn_number: generate_txn_number, amount_less_fees: amt_less_fees,                 
                status: @stripe_res.status, txn_available_at: @stripe_res.created, last4: @stripe_res.source.last4, 
                exp_month: @stripe_res.source.exp_month, exp_year: @stripe_res.source.exp_year, card_type: @stripe_res.source.brand, 
                card_name: @stripe_res.source.name, tax_percent: @merchant.tax_percent, destination: @stripe_res.destination, 
                team_id: @merchant.id, user_id: @user.id, notes: @msg, amount_with_taxes: amt_in_decimal(@stripe_res.amount),
                hashtag_id: @hashtag_id)
  end

  def amt_in_decimal(amt)
    (amt.to_f/100).round(2)
  end

  def big_decimal_2dp(amt)
    Toolbox::Decimal.to_2dp(amt)
  end

  def send_card_error_text
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

  def send_charge_failure_notification(err, to_merchant)
    EmailingService.charge_failure_notification(to: @merchant.email, customer_email: @user.email, customer_phone: @user.phone_number, card_name: @user.card_name, 
                                                  last4: @user.last4, text: @msg, org_phone: @merchant.org_phone, rhombus_number: @merchant.rhombus_number, 
                                                  dump: err, to_merchant: to_merchant)
  end

  def captured_transaction
    # call charge customer here
    payment_response_array = PaymentService.capture_payment(txn_uri)
    @stripe_res = payment_response_array[0]

    unless @stripe_res
      # notify platform
      return { error: "can't process" }
    end
    
    #send_text_receipt
    send_email_receipt  
    return { message: 'processed' }
  end

end

