# Transaction

# I need to Add receipt_sent_at back

class Transaction < ActiveRecord::Base
  include Transactionable
  include CSVHandler
  include PrettyDate

  has_one :message
  has_one :refund

  belongs_to :hashtag
  belongs_to :user
  belongs_to :team, class_name: 'User'
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

  def process_payment(amt, merchant, user, msg, hashtag_id, channel, capture=true)
    begin
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) }

      # taxes
      tax_multiplier = (((@merchant.tax_percent.to_f) / 100) + 1)
      @amt_with_taxes = (@amt.to_f * tax_multiplier).round

      # fees
      fees = calculate_fees_schedule
      @stripe_fee = ((@amt_with_taxes * fees[0]) - fees[1]).round
      @app_fee = merchant.is_platform? ? 0 : ((@amt_with_taxes * fees[2]) - fees[3]).round
      amount_less_fees = (@amount_with_taxes - @stripe_fee - @app_fee).round

      #puts 'got here so far'

      # charge
      @stripe_res_ary = PaymentService.charge(@amt_with_taxes, amount_less_fees, merchant, user, msg.text, capture)
      @stripe_res = @stripe_res_ary[0]

      #puts @stripe_res_ary.inspect

      # handle response
      if @stripe_res
        update_transaction_data
        [true, "Charge created"]
      else
        # if it is a card decline...we text only customers. Merchant might not have textable number on file.
        # this shouldnt be running cos ecah use case handles it ... except for texting... so pass in param to run this
        # send_card_error_text if @stripe_res_ary[3] && user.is_customer?
        # send_payment_failure_email(@stripe_res_ary[1], @stripe_res_ary[3]) # should go out only for text payments
        [false, @stripe_res_ary[2]]
      end
    rescue StandardError => err
      #send_payment_failure_email(err, false)  # should go out only for text payments
      [false, "Something went wrong"]
    end
  end

  def calculate_fees_schedule
    return Rails.application.secrets.fee_schedule if @merchant.is_platform?
    @fee_schedule = @merchant.get_stripe_cred[:cred].transaction_fee
    percent1, cents1 = @fee_schedule.provider_percent.to_f, @fee_schedule.provider_cents.to_f
    percent2, cents2 = @fee_schedule.platform_percent.to_f, @fee_schedule.platform_cents.to_f
    return percent1, cents1, percent2, cents2
  end

  def update_transaction_data
    # app_fee, stripe_fee are integers
    self.update(app_fee: @app_fee, stripe_fee: @stripe_fee,
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
    amt ||= self.amount_with_taxes
    Transaction.big_decimal_2dp(amt.to_f/100)
  end

  def self.big_decimal_2dp(amt)
    return 0 if (amt.blank? || amt == 0)
    Toolbox::Decimal.to_int_or_2dp(amt)
  end

  # remove this and just just the method below
  def send_card_error_text
    if @capture
      msg_to_send = "Your payment to #{@merchant.org_name} failed because: #{@stripe_res_ary.third}"
    else
      msg_to_send = ''
    end
    Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, @customer, 'user', @customer.id, msg_to_send, @channel)
  end

  def send_text_receipt(msg_to_send)
    msg_id = Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, @customer, 'user', @customer.id, msg_to_send, @channel)
  end

  def send_email_receipt
    # Also need to email merchant here too
    EmailingService.send_receipt(
      merchant_email: @merchant.email, to: @user.email,
      merchant_name: @merchant.org_name,
      transaction_number: self.txn_number,
      text: self.notes, transaction_date: self.created_at,
      amount: Transaction.big_decimal_2dp(self.amount),
      amt_with_taxes: Transaction.big_decimal_2dp(self.amount_with_taxes),
      org_phone: @merchant.org_phone,
      currency: @stripe_res.currency
    )
  end

  def send_payment_failure_email(err, to_merchant)
    EmailingService.charge_failure_notification(
      to: @merchant.email,
      customer_email: @user.email,
      customer_phone: @user.phone_number,
      card_name: @user.card_name,
      last4: @user.last4, text: @msg.text,
      org_phone: @merchant.org_phone,
      rhombus_number: @merchant.rhombus_number,
      dump: err, to_merchant: to_merchant
    )
  end

  def process_dashboard_txn(amt, merchant, user, msg, hashtag_id, capture=true, channel="Message")
    process_payment(amt, merchant, user, msg, hashtag_id, channel, capture)
    capture ? handle_captured_txn : handle_uncaptured_txn
  end

  def handle_captured_txn
    begin
      if @stripe_res
        send_text_receipt
        "Hi name, a payment of xyz was charged to your account by merchant_name"
        send_email_receipt
        # merchant also get their email
        [true, "Payment successful"]
      else
        if @stripe_res_ary[3]
          [false, 'Sorry, we were unable to complete this transaction because: ' + @stripe_res_ary.third]
          "Hi name, a charge of xyz by merchant_name failed because: #{@stripe_res_ary.third}"
        else
          [false, 'Sorry, we were unable to complete this transaction. Please try again later.']
        end
        # notify platform...
      end
    rescue StandardError => err
      # notify platform...
      [false, "Sorry, we were unable to complete this transaction. Please try again later."]
    end
  end

  def handle_uncaptured_txn
    begin
      if @stripe_res
        send_text_receipt
        "Hi name, amount has been preauthorized by merchant_name for item_name"
        [true, 'Transaction is authorized']
      else
        if @stripe_res_ary[3]
          [false, 'Sorry, we were unable to authorize transaction because: ' + @stripe_res_ary.third]
          "Hi name, we're unable to preauthorize a charge of xyz by merchant_name because: #{@stripe_res_ary.third}"
        else
          [false, "Sorry we were unable to authorize transaction. Please try again later."]
        end
        # notify platform...
      end
    rescue StandardError => err
      # notify platform...
      [false, "We were unable to authorize transaction. Please try again later."]
    end
  end

  # https://support.stripe.com/questions/does-stripe-support-authorize-and-capture
  def capture_uncaptured_txn(merchant, user, charge_id, channel="Message")
    begin
      @capture = true
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) if arg != :charge_id }
      payment_ary = PaymentService.process_captured_charge(charge_id)
      if payment_ary[0]
        ###### will capture change transaction status and date???
        self.update(captured: true)
        send_text_receipt("adasdsa")
        "Hi name, the preauthorized transaction of xyz has been charged to your account by merchant_name"
        send_email_receipt
        # merchant gets email too
        [true, "The preauthorized charge of xyz has been processed."]
      else
        if @stripe_res_ary[3]
          [false, 'Sorry, we were unable to complete this transaction because: ' + @stripe_res_ary.third]
          "Hi name, a charge of xyz by merchant_name failed because: #{@stripe_res_ary.third}"
        else
          [false, 'Sorry, we were unable to complete this transaction. Please try again later.']
        end
        # notify platform only.
      end
    rescue StandardError => err
      # notify platform only.
      [false, "Sorry, we were unable to complete this transaction. Please try again later."]
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
    "#{Transaction.big_decimal_2dp(self.amount_with_taxes)}"
  end

  def txn_amount_less_fees
    amt = self.amount_with_taxes - self.app_fee.to_f/100 - self.stripe_fee.to_f/100
    "#{Transaction.big_decimal_2dp(amt)}"
  end

  def relative_time
    time_in_relative_form(self.created_at, 'short_format')
  end
end
