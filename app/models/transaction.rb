class Transaction < ActiveRecord::Base
  include CSVHandler
  include PrettyDate
  include Transactionable

  has_one :message
  has_one :refund

  belongs_to :hashtag
  belongs_to :user
  belongs_to :team, class_name: 'User'
  belongs_to :transaction_fee
  belongs_to :subscription

  delegate :name, to: :hashtag, prefix: :item, allow_nil: true
  delegate :email, to: :user, prefix: :customer
  delegate :email, :name, to: :team, prefix: :business

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

  def process_payment(amt, merchant, customer, msg, hashtag, channel, source = 'text', capture = true)
    begin
      method(__method__).parameters.each { |_,arg| instance_variable_set("@#{arg}", binding.local_variable_get(arg)) unless [:capture].include?(arg) }

      # taxes # tested
      @amt_with_taxes = TransactionFee.amount_with_taxes(@amt, @merchant.tax_percent)

      # fees   # tested
      fees = get_fees_schedule
      @stripe_fee = ((@amt_with_taxes * (fees[0]/100)) + fees[1]).round
      @app_fee = ((@amt_with_taxes * (fees[2]/100)) + fees[3]).round
      amount_less_fees = (@amt_with_taxes - @stripe_fee - @app_fee).round

      # charge # tested
      # is this right for managed account?
      @stripe_res_ary = PaymentService.charge(@amt_with_taxes, amount_less_fees, merchant, customer, @msg, capture)
      @stripe_res = @stripe_res_ary.first
      puts @stripe_res_ary.inspect

      # handle response
      if @stripe_res # tested
        update_transaction_data
        return [true, "Transaction processed"]
      else
        # This should only run for text based payments. Dashboard payments is handled differently.
        if @source == 'text'
          # if it is a card decline, we text only customers. Merchant might not have textable number on file.
          if customer.is_customer?
            if @stripe_res_ary[3]
              send_response("We're sorry your payment to #{merchant.org_name} failed because: #{@stripe_res_ary[2]}")
            else
              send_response("We're sorry your payment to #{merchant.org_name} failed. Please try again later.")
            end
          end
          # send_payment_failure_email(@stripe_res_ary[1], @stripe_res_ary[3])
        end
        [false, @stripe_res_ary[2]]
      end
    rescue StandardError => err
      ExceptionNotifier.notify_exception(err, data: { message: 'From process_payment in transaction.rb', res: @stripe_res_ary, env: Rails.env, self: self, merchant: merchant, customer: customer, amt: amt })
      #send_payment_failure_email(err, false)  # should go out only for text payments
      [false, 'Something went wrong']
    end
  end

  def receipt_options
    {
      merchant: team,
      customer: user,
      amount: txn_amount,
      transaction_id: txn_number,
      created_at: created_at.strftime('%B %d, %Y | %-I:%M%P'),
      status: status.capitalize,
      last4: last4,
      exp_month: exp_month,
      exp_year: exp_year,
      description: description,
      taxes_and_fees: taxes_and_fees,
      amount_less_fees: txn_amount_less_fees,
      total_amount: Transaction.big_decimal_2dp(amount_with_taxes),
      relay_number: team.friendly_relay_number,
      currency: currency,
      currency_symbol: '$'
    }
  end

  # tested
  def get_fees_schedule
    @fee_schedule = @merchant.is_platform? ? TransactionFee.platform.first : @merchant.get_stripe_cred[:cred].transaction_fee
    percent1, cents1 = @fee_schedule.provider_percent.to_f, @fee_schedule.provider_cents.to_f
    percent2, cents2 = @fee_schedule.platform_percent.to_f, @fee_schedule.platform_cents.to_f
    return percent1, cents1, percent2, cents2
  end

  # tested
  def update_transaction_data
    # app_fee, stripe_fee are integers
    self.update(app_fee: @app_fee, stripe_fee: @stripe_fee,
                amount: amt_in_decimal(@amt), amount_with_taxes: amt_in_decimal(@stripe_res.amount),
                currency: @stripe_res.currency, txn_uri: @stripe_res.id, txn_number: generate_txn_number,
                status: @stripe_res.status, txn_available_at: @stripe_res.created, last4: @stripe_res.source.last4,
                card_name: @stripe_res.source.name, tax_percent: @merchant.tax_percent, destination: @stripe_res.destination,
                team_id: @merchant.id, user_id: @customer.id, notes: @msg, hashtag_id: @hashtag.try(:id), captured: @stripe_res.captured,
                exp_month: @stripe_res.source.exp_month, exp_year: @stripe_res.source.exp_year, card_type: @stripe_res.source.brand,
                description: "Payment to #{@merchant.email}. #{@merchant.org_name}. Relay number: #{@merchant.rhombus_number}",
                transaction_fee_id: @fee_schedule.id)
  end

  # tested
  def send_payment_responses(msg_to_send, media = [])
    send_response(msg_to_send, media)
    EmailingService.customer_receipt(receipt_options)
    EmailingService.customer_transaction_detail(receipt_options)
  end

  # tested
  def send_response(msg_to_send, media = [])
    Conversation.find_or_create_conversation_for_message_and_send_publish(@merchant, @customer, 'user', @customer.id, msg_to_send, @channel, media)
  end

  def send_payment_failure_email(err, to_merchant)
    EmailingService.charge_failure_notification(
      to: @merchant.email,
      customer_email: @customer.email,
      customer_phone: @customer.phone_number,
      card_name: @customer.card_name,
      last4: @customer.last4, text: @msg,
      org_phone: @merchant.org_phone,
      rhombus_number: @merchant.rhombus_number,
      dump: err, to_merchant: to_merchant
    )
  end

  def process_dashboard_txn(amt, merchant, user, msg, hashtag=nil, capture=true, channel="Message", source='account-reload')
    process_payment(amt, merchant, user, msg, hashtag, channel, source, capture)
    capture ? handle_captured_txn : handle_uncaptured_txn
  end

  def handle_captured_txn
    begin
      if @stripe_res
        if @source == 'dashboard-txn'
          send_payment_responses("Hi" + customer_first_name + ", a payment of #{txn_amount} (#{self.currency}) was charged to your account by #{@merchant.org_name}.")
        end
        [true, "Payment successful"]
      else
        if @stripe_res_ary[3]
          if @source == 'dashboard-txn'
            send_response("Hi" + customer_first_name + ", a charge of #{txn_amount} (#{self.currency}) by #{@merchant.org_name} failed because: #{@stripe_res_ary.third}")
          end
          [false, 'Sorry, we were unable to complete this transaction because: ' + @stripe_res_ary.third]
        else
          [false, 'Sorry, we were unable to complete this transaction. Please try again later.']
        end
      end
    rescue StandardError => err
      ExceptionNotifier.notify_exception(err, data: { message: "From handled_captured_txn in transaction.rb", self: self, res: @stripe_res_ary, merchant: @merchant, customer: @customer, amt: @amt })
      [false, "Sorry, we were unable to complete this transaction. Please try again later."]
    end
  end

  def handle_uncaptured_txn
    begin
      if @stripe_res
        send_response("Hi" + customer_first_name + ", #{txn_amount} (#{self.currency}) has been authorized by #{@merchant.org_name} for #{@hashtag.name}.")
        [true, 'Transaction is authorized']
      else
        if @stripe_res_ary[3]
          send_response("Hi" + customer_first_name + ", we're unable to authorize a charge of #{txn_amount} (#{self.currency}) by #{@merchant.org_name} because: #{@stripe_res_ary.third}")
          [false, 'Sorry, we were unable to authorize transaction because: ' + @stripe_res_ary.third]
        else
          [false, "Sorry we were unable to authorize transaction. Please try again later."]
        end
      end
    rescue StandardError => err
      ExceptionNotifier.notify_exception(err, data: { message: "From handle_uncaptured_txn in transaction.rb", self: self, res: @stripe_res_ary, merchant: @merchant, customer: @customer, amt: @amt })
      [false, "We were unable to authorize transaction. Please try again later."]
    end
  end

  # https://support.stripe.com/questions/does-stripe-support-authorize-and-capture
  def capture_uncaptured_txn
    begin
      @channel, @merchant, @customer = "Message", self.team, self.user
      payment_ary = PaymentService.capture_charge(self.txn_uri, @merchant)
      if payment_ary[0]
        self.update_column(:captured, true)
        send_payment_responses("Hi" + customer_first_name + ", the preauthorized transaction of #{txn_amount} (#{self.currency}) has been charged to your account by #{@merchant.org_name}.")
        [true, "The preauthorized transaction has been processed."]
      else
        [false, payment_ary[2]]
      end
    rescue StandardError => err
      ExceptionNotifier.notify_exception(err, data: { message: "From capture_uncaptured_txn in transaction.rb", env: Rails.env, self: self, re: payment_ary })
      [false, "Sorry, we were unable to complete this transaction. Please try again later."]
    end
  end

  # tested
  def amt_in_decimal(amt)
    Transaction.big_decimal_2dp(amt.to_f/100)
  end

  # tested
  def self.big_decimal_2dp(amt)
    return 0 if (amt.blank? || amt == 0)
    Toolbox::Decimal.to_int_or_2dp(amt)
  end

  def customer_first_name
    @customer.first_name.present? ? " " + @customer.first_name : ''
  end

  def txn_amount
    "#{Transaction.big_decimal_2dp(self.amount_with_taxes)}"
  end

  def txn_amount_less_fees
    amt = self.amount_with_taxes - self.app_fee.to_f/100 - self.stripe_fee.to_f/100
    "#{Transaction.big_decimal_2dp(amt)}"
  end

  def taxes_and_fees
    tax_amt = (amount_with_taxes - amount).to_f
    fees_amt = app_fee.to_f/100 + stripe_fee.to_f/100
    "#{ Toolbox::Decimal.to_int_or_2dp(tax_amt + fees_amt) }"
  end

  def relative_time
    time_in_relative_form(self.created_at, 'short_format')
  end
end
