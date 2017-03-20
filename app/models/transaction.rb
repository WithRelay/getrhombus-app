class Transaction < ActiveRecord::Base

  include Transactionable
  include CSVHandler
  include PrettyDate

  has_one :message
  has_one :refund
  has_many :notification_logs, as: :notifiable, dependent: :destroy

  belongs_to :hashtag
  belongs_to :user, counter_cache: true
  belongs_to :team, class_name: "User", counter_cache: true
  belongs_to :transaction_fee
  
  # Exclude refunded transactions, include subscriptions since these queries are read only
  # and include only captured transactions and reloads are included by default..right
  scope :exclude_refunded_transactions, -> () { self.joins('LEFT JOIN refunds on transactions.id = refunds.transaction_id')
                                                          .where("refunds.transaction_id is null") }

  # add this in queries for transactions that may be refunded. subscriptions arent easily refunded                                                        
  scope :exclude_subscriptions, -> () { self.where(subscription_id: nil) }

  scope :only_captured_transactions, -> () { self.where(captured: true) }
  scope :only_uncaptured_transactions, -> () { self.where(captured: false) }

  scope :get_merchant_todays_last5_txns, -> (team_id, date) { self.includes(:user).exclude_refunded_transactions().where(team_id: team_id)
                                                                  .only_captured_transactions().where("transactions.created_at >= ?", date)
                                                                  .order(created_at: :desc).limit(5) }

  scope :get_merchant_todays_txn_count, -> (team_id, date) { self.exclude_refunded_transactions().only_captured_transactions()
                                                                  .where("transactions.created_at >= ? and team_id = ?", date, team_id).count }
  
  scope :user_average_transaction_with_merchant, -> (user_id, team_id) { big_decimal_2dp(self.exclude_refunded_transactions().only_captured_transactions
                                                                                            .where(user_id: user_id, team_id: team_id).average(:amount)) }

  scope :user_total_transaction_with_merchant, -> (user_id, team_id) { big_decimal_2dp(self.exclude_refunded_transactions().only_captured_transactions()
                                                                                          .where(user_id: user_id, team_id: team_id).sum(:amount)) }


  # send in a hash instead to PaymentService?
  def process_payment(amt, merchant, user, msg, hashtag_id, channel, capture=true)
    begin
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) }

      tax_multiplier = (((@merchant.tax_percent.to_f) / 100) + 1)                                         # default is 0
      @amt_with_taxes = (@amt.to_f * tax_multiplier).round                                              # total amount to charge
      
      fees = calculate_fees_schedule
      @amt_less_stripe_fee = ((@amt_with_taxes * fees[0]) - fees[1]).round  
      @app_fee = ((@amt_with_taxes * fees[2]) - fees[3]).round         
                                          
      #puts 'got here so far'

      @stripe_res_ary = PaymentService.charge(@amt_with_taxes, @amt_less_stripe_fee, @app_fee, merchant, user, msg.text, capture)
      @stripe_res = @stripe_res_ary[0]

      #puts @stripe_res_ary.inspect

      if @stripe_res
        update_transaction_data
        [true, "Transaction done"]
      else
        # true if it is a card decline...we text only customers. Merchant might not have textable number on file.
        #send_card_error_text if @stripe_res_ary[3] && user.is_customer?
        #send_payment_failure_email(@stripe_res_ary[1], @stripe_res_ary[3])
        [false, @stripe_res_ary[2]]
      end
    rescue StandardError => err
      #send_payment_failure_email(err, false)
      [false, "Something went wrong"]
    end
  end

  def calculate_fees_schedule
    return 0.029, 30, 0, 0      # take this line out
    @fee_schedule = @merchant.get_stripe_cred.transaction_fee
    percent1, cents1 = @fee_schedule.provider_percent.to_f, @fee_schedule.provider_cents.to_f
    percent2, cents2 = @fee_schedule.platform_percent.to_f, @fee_schedule.platform_cents.to_f
    return percent1, cents1, percent2, cents2
  end

  def update_transaction_data
    # storing this in intger, other amount columns need to be changed to integer...consistent with Stripe
    _stripe_fee = @amt_with_taxes - @amt_less_stripe_fee

    self.update(app_fee: amt_in_decimal(@app_fee), stripe_fee: _stripe_fee,
                amount: amt_in_decimal(@amt), amount_with_taxes: amt_in_decimal(@stripe_res.amount),
                currency: @stripe_res.currency, txn_uri: @stripe_res.id, txn_number: generate_txn_number,
                status: @stripe_res.status, txn_available_at: @stripe_res.created, last4: @stripe_res.source.last4,
                card_name: @stripe_res.source.name, tax_percent: @merchant.tax_percent, destination: @stripe_res.destination,
                team_id: @merchant.id, user_id: @user.id, notes: @msg.text, hashtag_id: @hashtag_id, captured: @stripe_res.captured,
                exp_month: @stripe_res.source.exp_month, exp_year: @stripe_res.source.exp_year, card_type: @stripe_res.source.brand,
                description: "Payment to #{@merchant.email}. #{@merchant.org_name}. rhombus number: #{@merchant.rhombus_number}",
                transaction_fee_id: @fee_schedule.id)
  end

  def amt_in_decimal(amt)
    Transaction.big_decimal_2dp(amt.to_f/100)
  end

  def self.big_decimal_2dp(amt)
    return 0 if amt.nil? || amt == 0
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
    msg_id = Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, @customer, 'user', @customer.id, msg_to_send, @channel)
    self.notification_logs.create(notify_type: 'new_transaction', reason: 'receipt', channel: @channel, channel_id: msg_id)
  end

  def send_email_receipt
    # Also need to email merchant here too
    EmailingService.send_receipt(merchant_email: @merchant.email, to: @user.email, merchant_name: @merchant.org_name, transaction_number: self.txn_number,
                                  text: self.notes, transaction_date: self.created_at, amount: Transaction.big_decimal_2dp(self.amount),
                                  amt_with_taxes: Transaction.big_decimal_2dp(self.amount_with_taxes), org_phone: @merchant.org_phone, currency: @stripe_res.currency)
    # Log email notification
    self.notification_logs.create(notify_type: 'new_transaction', reason: 'receipt', channel: 'Email')
  end

  def send_payment_failure_email(err, to_merchant)
    # change text based on capture or not
    # if @capture

    EmailingService.charge_failure_notification(to: @merchant.email, customer_email: @user.email, customer_phone: @user.phone_number, card_name: @user.card_name,
                                                  last4: @user.last4, text: @msg.text, org_phone: @merchant.org_phone, rhombus_number: @merchant.rhombus_number,
                                                  dump: err, to_merchant: to_merchant)
  end

  def process_dashboard_txn(amt, merchant, user, msg, hashtag_id, capture=true, channel="Message")
    process_payment(amt, merchant, user, msg, hashtag_id, channel, capture)
    capture ? handle_captured_txn : handle_uncaptured_txn
  end

  def handle_captured_txn
    begin
      unless @stripe_res
        # notify platform...should we email merchant too? could be a security measure.
        [true, "Payment successful"]
      else
        send_text_receipt
        send_email_receipt
        unless @stripe_res_ary[3]
          [false, 'Unable to process txn because: ' + @stripe_res_ary[2]]
        else
          [false, 'Stripe is unable to provess this transaction.']
        end
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

  def customer_email
    "#{self.user.email}"
  end

  def business_name
    "#{self.team.org_name}"
  end

  def business_email
    "#{self.team.email}"
  end

  def txn_amount
    "#{Transaction.big_decimal_2dp(self.amount)}"
  end

  def txn_amount_less_fees
    "#{Transaction.big_decimal_2dp(self.amount_less_fees)}"
  end

  def relative_time
    time_in_relative_form(self.created_at, 'short_format')
  end

end
