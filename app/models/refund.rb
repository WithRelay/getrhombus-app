class Refund < ActiveRecord::Base

  validates :uri, :time, presence: true
  belongs_to :txn, foreign_key: :transaction_id, class_name: :Transaction

  # Stripe no longer refunds its fees for accounts created after this date
  STRIPE_TZ = "Pacific Time (US & Canada)".freeze
  STRIPE_NO_FEES_REFUND_DATE = "September 14, 2017".freeze
  STRIPE_REFUND_REASONS = ['fraudulent', 'duplicate', 'requested_by_customer'].freeze

  # Only managed account txns can be refunded.
  # We aren't refunding Standalone acct txns going forward once we move to managed accounts.
  def refund_card_txn(merchant, params)
    begin
      customer_txn = Transaction.includes(:refund, :team, :user).where(txn_number: params[:txn_number]).first
      is_platform = merchant.is_platform?

      if customer_txn.nil?
        [false, "Transaction doesn't exists.".freeze]
      elsif customer_txn.refund.present?
        [false, "Transaction has already been refunded.".freeze]
      elsif !is_platform && customer_txn.team_id != merchant.id            # For admin refunds.
        [false, "Transaction wasn't created by you.".freeze]
      else
        params[:charge_id] = customer_txn.txn_uri
        params[:reason] = 'requested_by_customer' unless STRIPE_REFUND_REASONS.include? params[:reason]

        cred = merchant.get_stripe_cred
        re = PaymentService.refund_charge(params, cred, is_platform)

        if re.first
          fee = cred[:cred].created_at.in_time_zone(STRIPE_TZ).to_i >= STRIPE_NO_FEES_REFUND_DATE.in_time_zone(STRIPE_TZ).to_i ? customer_txn.stripe_fee : 0
          amt_refunded = Toolbox::Decimal.to_cents(customer_txn.amount_with_taxes) - fee
          self.update(uri: re.first.id, time: re.first.created, reason: params[:reason], transaction_id: customer_txn.id, amount_refunded: amt_refunded)
          send_refund_notification(customer_txn)
          [true, "Payment has been refunded.".freeze]
        else
          [false, "We're unable to refund this transaction. Please try again later.".freeze]
        end
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In refund_card_txn", re: re, env: Rails.env, self: self, merchant: merchant, params: params } )
      [false, "We're unable to refund this transaction. Please try again later.".freeze]
    end
  end

  # Refund notification
  def send_refund_notification(customer_txn)
    merchant = customer_txn.team
    date = DateTime.strptime(time, '%s').in_time_zone(merchant.time_zone)
    options = {
      merchant_first_name: merchant.first_name,
      merchant_business_name: merchant.org_name,
      merchant_email: merchant.email,
      currency: customer_txn.currency,
      currency_symbol: '$',
      date: date.strftime('%B %d, %Y | %-I:%M%P'),
      amount: Toolbox::Decimal.to_int_or_2dp(amount_refunded.to_f/100),
      user: customer_txn.user
    }
    EmailingService.refund_processed(options)
  end

end
