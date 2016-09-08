class Refund < ActiveRecord::Base
  
  validates :uri, :time, presence: true
  belongs_to :txn, :foreign_key => :transaction_id, :class_name => :Transaction


  # return response text and http code
  def self.refund_card_txn(charge_id, merchant_id, uid, reason, admin)
    begin     
      txn = Transaction.find_by(transaction_uri: charge_id) 
      
      if txn.nil? || ( !(txn.team_id == merchant_id) && !admin )  # check if merchant created this txn
        send_refund_failure_notification
        return ["We're unable to refund this transaction. It might already be refunded, doesnt exists or wasn't created by you.", 403]
      end
      
      re = PaymentService.refund_charge(charge_id, uid)   # else proceed to refund on Stripe
      if re[0]
        Refund.create(uri: re[0].id, time: re[0].created, reason: reason, transaction_id: txn.id)
=begin
        # Refund notification
        EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
          card_name: user.card_name, last4: user.last4, text: message, org_phone: merchant.org_phone,
          rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
=end
        return ["Payment has been refunded.", 200]
      end
      error = re[1]
    rescue StandardError => err
      error = err
    end 
    send_refund_failure_notification
    return ["We're unable to refund this transaction. Please try again later.", 500]
  end

  # Refund failure notification
  def send_refund_failure_notification
    EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
      card_name: user.card_name, last4: user.last4, text: message, org_phone: merchant.org_phone,
      rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
  end

end