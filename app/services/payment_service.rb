class PaymentService

  class << self
    
    # return array with txn status, error object, notify customer/merchant
    def charge(amount_with_taxes, merchant, user, message, capture)
      begin
        response = Stripe::Charge.create({
          amount: amount_with_taxes, # in cents
          currency: merchant.currency ? merchant.currency : "usd",
          source: user.instrument_uri,
          capture: capture,
          description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.",
          destination: merchant.stripe_access_token
          # statement_descriptor: '',
          # application_fee: rhombus_fee
          metadata: {
            "message" => message
          }            
        })
        [response]
      rescue Stripe::CardError => e               # Since it's a decline, Stripe::CardError will be caught
        false, e.json_body[:error], true
      rescue Stripe::StripeError => e
        false, e.json_body[:error]
      rescue StandardError => err
        false, err
      end
    end

    # returns array with refund status, error object
    def refund_charge(charge_id)
      begin
        re = Stripe::Refund.create(charge: charge_id)
        [re]
      rescue Stripe::StripeError => e
        false, e.json_body[:error]
      rescue StandardError => err
        false, err
      end 
    end

  end  
end

