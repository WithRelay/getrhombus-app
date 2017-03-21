class Refund < ActiveRecord::Base
  
  validates :uri, :time, presence: true
  belongs_to :txn, foreign_key: :transaction_id, class_name: :Transaction

  # Only managed account txns can be refunded. 
  # We aren't refunding Standalone acct txns going forward once we move to managed accounts.
  def self.refund_card_txn(merchant_id, params, is_admin)
    begin     
      txn = Transaction.where(txn_number: params[:txn_number]).first 
      
      if txn.nil?
        [false, "Transaction doesnt exists."]
      elsif txn.refund.nil?
        [false, "Transaction has already been refunded."]
      # temp option for admin refunds
      elsif !is_admin && txn.team_id != merchant_id
        [false, "Transaction wasn't created by you."]
      else
        refund_reason = params[:reason]
        params[:reason] = 'requested_by_customer' unless STRIPE_REFUND_REASONS.include? params[:reason]

        re = PaymentService.refund_charge(params)
        if re.first
          Refund.create(uri: re.second.id, time: re.second.created, reason: refund_reason, transaction_id: txn.id)
          send_refund_notification
          [true, "Payment has been refunded."]
        else 
          [false, "We're unable to refund this transaction. Please try again later."]
        end
      end     
    rescue StandardError => err
      # notify team of error
      [false, "We're unable to refund this transaction. Please try again later."]
    end 
  end

  # Refund notification
  def send_refund_notification
    #EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
     # card_name: user.card_name, last4: user.last4, text: message, org_phone: merchant.org_phone,
      #rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
  end

end