class Refund < ActiveRecord::Base

  validates :uri, :time, presence: true
  belongs_to :txn, foreign_key: :transaction_id, class_name: :Transaction

  # Only managed account txns can be refunded.
  # We aren't refunding Standalone acct txns going forward once we move to managed accounts.
  def refund_card_txn(merchant, params)
    begin
      txn = Transaction.includes(:refund).where(txn_number: params[:txn_number]).first
      is_platform = merchant.is_platform?

      if txn.nil?
        [false, "Transaction doesn't exists."]
      elsif txn.refund.present?
        [false, "Transaction has already been refunded."]
      elsif !is_platform && txn.team_id != merchant.id            # For admin refunds.
        [false, "Transaction wasn't created by you."]
      else
        params[:charge_id] = txn.txn_uri
        params[:reason] = 'requested_by_customer' unless STRIPE_REFUND_REASONS.include? params[:reason]

        re = PaymentService.refund_charge(params, merchant)

        if re.first
          self.update(uri: re.first.id, time: re.first.created, reason: params[:reason], transaction_id: txn.id)
          send_refund_notification
          [true, "Payment has been refunded."]
        else
          [false, "We're unable to refund this transaction. Please try again later."]
        end
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In refund_card_txn" } )
      [false, "We're unable to refund this transaction. Please try again later."]
    end
  end

  # Refund notification
  def send_refund_notification
    #EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
     # card_name: user.card_name, last4: user.last4, text: message, org_phone: merchant.org_phone,
      #rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
    merchant = txn.team
    date = DateTime.strptime(time, '%s').in_time_zone(merchant.time_zone)
    options = {
      merchant_first_name: merchant.first_name,
      merchant_business_name: merchant.org_name,
      currency: txn.currency,
      currency_symbol: '$',
      date: date.strftime('%B %d,%Y | %I:%M%P'),
      amount: txn.amount_with_taxes,
      user: txn.team
    }
    EmailingService.refund_processed(options)
  end

end
