class Refund < ActiveRecord::Base
  
  validates :uri, :time, presence: true
  # Normally, the transaction foreign key would be here
  # But reversed it because each transaction has 3 rows for user, merchant and admin, and they all need to be set.
  has_many :transactions, inverse_of: :refund

  def self.refund_card_txn(charge_id, merchant_id, reason, admin)
      begin
          txns = Transaction.where("transaction_uri = ? and refund_id is NULL", charge_id) 
          if txns.empty? || ( !txns.find_by(referenced_merchant_id: merchant_id) && !admin )  # check if merchant created this txn
=begin
            EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
            card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
            rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
=end
            return ["We're unable to refund this transaction. It might already be refunded, doesnt exists or wasn't created by you.", 403]
        end
        
        # else proceed to refund on Stripe
        re = Stripe::Charge.retrieve(charge_id).refund
        # create a new refund
        ref_id = Refund.create(uri: re.refunds[0].id, time: re.refunds[0].created, reason: reason).id
          sql = ActiveRecord::Base.send(:sanitize_sql_array, ["UPDATE transactions SET refund_id = ? WHERE transaction_uri = ? ", ref_id, charge_id ])
      Refund.connection.execute(sql)
=begin
      # email merchant, user, team@
        EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
            card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
            rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
        EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
            card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
            rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
=end
        return ["Payment has been refunded.", 200]
      rescue Stripe::StripeError => e
        logger.debug e
=begin
          EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
          card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
          rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
=end
        return ["Stripe is unable to refund this transaction at this time. Please try again later.", 500]      
      rescue StandardError => e
=begin
          EmailingService.charge_failure_notification(to: merchant.email, customer_email: user.email, customer_phone: user.phone_number,
          card_name: user.card_name, last_four: user.last_four, text: message, business_phone: merchant.business_phone,
          rhombus_number: merchant.rhombus_number, dump: err, to_merchant: true)
=end
        return ["Something went wrong on our end and we're unable to refund this transaction. Please try again later.", 500]
      end 
    end



end