class Transaction < ActiveRecord::Base

  include Transactionable
  include CSVHandler
  # scope :ordering, -> { order(:DESC) }

  has_one :message
  has_one :refund
  has_many :notification_logs, as: :notifiable, dependent: :destroy

  belongs_to :hashtag
  belongs_to :merchant_customer
  belongs_to :user, counter_cache: true
  belongs_to :team, class_name: "User", counter_cache: true

=begin
  # Why am I passing an array in here?
  # Capture can change transaction status and date
  # Each transaction generates 3 rows. This will be normalized in future updates
  # This method support captured payment, charge a customer and sms payment
  # does this include hashtag_id
  # send in a hash instaed to PaymentService

  def process_text_payment(amt_ary, merchant, user, msg) 
    begin    
      create_stripe_charge(amt_ary[0], merchant, user, msg, true)
      @stripe_res = @stripe_response_array[0]

      unless @stripe_res
        if @stripe_response_array[2]
          message = Message.new
          message.send_and_save_message(@merchant.rn_type, @merchant.rhombus_number, @user.phone_number, "Your payment to #{@merchant.org_name} failed because: #{err[:message]}")
          # Send to merchant's messaging channel
          RealtimeStreamService.send_message_via_number(@user.phone_number, @merchant.rhombus_number, message.text, message.created_at, true)        
        end
        send_charge_failure_notification(@stripe_response_array[1], @stripe_response_array[2])
        return
      end
    
      update_transaction_data
      send_text_receipt
      send_email_receipt  
    rescue StandardError => err
      send_charge_failure_notification(err, false)
    end
  end

  def process_dashboard_transaction(amt, merchant, _user_id, msg, capture=true)
    create_stripe_charge(amt, merchant, User.find _user_id, msg, capture)
  end

  def create_stripe_charge(merchant, user, amt, msg, capture)
    @merchant = merchant
    @user = user
    @msg = msg

    @amt = amt
    tax_percent = (((@merchant.tax_percent.to_f) / 100) + 1)                     # default is 0

    @amt_with_taxes = (@amt.to_f * tax_percent).round      
    @app_fee = ((Rails.application.secrets.app_fee_percent.to_f / 100) * @amt_with_taxes).round

    @stripe_response_array = PaymentService.charge(@amt_with_taxes, merchant, user, msg, capture)
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

  def update_transaction_data
    # This might need to change if we charge merchants different fees
    amt_less_fees = amt_in_decimal(@amt_with_taxes.to_f - @app_fee.to_f - ((@amt_with_taxes.to_f * 0.029) + 0.3))     # this line first

    # Note since relationship between user and card is one to one, when merchant and owner info is saved,
    # it is pulled from user profile and not transaction data. This changes with x to many relationships.
    # Add hashtag_id option
    self.update(currency: @stripe_res.currency, captured: @stripe_res.captured, application_fee: amt_in_decimal(@app_fee),
                description: "Payment to #{@merchant.email}. #{@merchant.org_name}. rhombus number: #{@merchant.rhombus_number}", 
                txn_uri: @stripe_res.id, amount: amt_in_decimal(@amt), txn_number: generate_txn_number, amount_less_fees: amt_less_fees,                 
                status: @stripe_res.status, txn_available_at: @stripe_res.created, last4: @stripe_res.source.last4, exp_month: @stripe_res.source.exp_month, 
                exp_year: @stripe_res.source.exp_year, card_type: @stripe_res.source.brand, card_name: @stripe_res.source.name, tax_percent: @merchant.tax_percent, 
                destination: @stripe_res.destination, team_id: @merchant.id, user_id: @user.id, notes: @msg, amount_with_taxes: amt_in_decimal(@stripe_res.amount))
  end

  def amt_in_decimal(amt)
    (amt.to_f/100).round(2)
  end

  def big_decimal_2dp(amt)
    sprintf("%.2f", amt)
  end

  # receipts for capture should be different
  def send_text_receipt
    first_name = (@user.card_name.present?) ? " " + @user.card_name.split.first : ''
    msg_to_send = "Thanks" + first_name + ". A payment of #{amt_in_decimal(@stripe_res.amount)} (#{@stripe_res.currency}) "
    msg_to_send = msg_to_send + (@merchant.tax_percent == "0" ? "was sent to #{@merchant.org_name}." : "plus taxes and fees set by #{@merchant.org_name} was sent."

    msg = Message.new
    msg.send_and_save_message(@merchant.rn_type, @merchant.rhombus_number, @user.phone_number, msg_to_send)
    
    # Log sms notification
    self.notification_logs.create(notify_type: 'new_transaction', reason: 'receipt', channel: 'Message', channel_id: msg.id)    
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
=end

end

