class Refund < ActiveRecord::Base
  
  validates :uri, :time, presence: true
  belongs_to :txn, foreign_key: :transaction_id, class_name: :Transaction

  # Only managed account txns can be refunded. 
  # We aren't refunding Standalone acct txns going forward once we move to managed accounts.
  def self.refund_card_txn(merchant_id, params, is_admin)
    begin     
      txn = Transaction.where(transaction_uri: params[:charge_id]).first 
      
      if txn.nil?
        ["Transaction doesnt exists.", 404]
      elsif txn.refund.nil?
        ["Transaction has already been refunded.", 403]
      # temp option for admin refunds
      elsif !is_admin && txn.team_id != merchant_id
        ["Transaction wasn't created by you.", 403]
      else
        re = PaymentService.refund_charge(params)
        if re.first
          Refund.create(uri: re.second.id, time: re.second.created, reason: params[:reason], transaction_id: txn.id)
          send_refund_notification
          ["Payment has been refunded.", 200]
        else 
          ["We're unable to refund this transaction. Please try again later.", 500]
        end
      end     
    rescue StandardError => err
      # notify team of error
      ["We're unable to refund this transaction. Please try again later.", 500]
    end 
  end

  # Refund notification
  def send_refund_notification
    #EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
     # card_name: user.card_name, last4: user.last4, text: message, org_phone: merchant.org_phone,
      #rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
  end

end