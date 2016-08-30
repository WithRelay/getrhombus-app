class Refund < ActiveRecord::Base
  
  validates :uri, :time, presence: true

  # Normally, the transaction foreign key would be here
  # But reversed it because each transaction has 3 rows for user, merchant and admin, and they all need to be set.
  # This should change when transaction table is further normalized
  has_many :transactions, inverse_of: :refund


  # return response text and http code
  def self.refund_card_txn(charge_id, merchant_id, reason, admin)
    begin     
      txns = Transaction.where("transaction_uri = ? and refund_id is NULL", charge_id) 
      if txns.empty? || ( !txns.find_by(referenced_merchant_id: merchant_id) && !admin )  # check if merchant created this txn
        send_refund_failure_notification
        return ["We're unable to refund this transaction. It might already be refunded, doesnt exists or wasn't created by you.", 403]
      end
      
      re = PaymentService.refund_charge(charge_id)   # else proceed to refund on Stripe
      if re[0]
        ref_id = Refund.create(uri: re[0].id, time: re[0].created, reason: reason).id
        ActiveRecord::Base.connection.execute("UPDATE transactions SET refund_id = #{ref_id} WHERE transaction_uri = #{charge_id}") 
=begin
        # Refund notification
        EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
          card_name: user.card_name, last_four: user.last_four, text: message, org_phone: merchant.org_phone,
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
      card_name: user.card_name, last_four: user.last_four, text: message, org_phone: merchant.org_phone,
      rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
  end

end