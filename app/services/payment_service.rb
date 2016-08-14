class PaymentService
  
  class << self
    
    def charge(amount_with_taxes, merchant, user, message, capture)

      begin
        response = Stripe::Charge.create({
              amount: amount_with_taxes, # in cents
              currency: merchant.currency ? merchant.currency : "usd",
              source: user.instrument_uri,
              capture: capture,
              description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.",
              destination: merchant.stripe_access_token
              #statement_descriptor: '',
              #:application_fee => rhombus_fee
              metadata: {
                "message" => message
              }            
            })

        return [response]
      rescue Stripe::CardError => e               # Since it's a decline, Stripe::CardError will be caught
        body = e.json_body
        err  = body[:error]
        # txn status, error object, notify customer/merchant
        return false, err, true
      rescue Stripe::StripeError => e
          body = e.json_body
          err  = body[:error]
          return false, err
      rescue StandardError => err
          return false, err
      end

    end

    def refund_charge(charge_id)
      begin
        re = Stripe::Refund.create(charge: charge_id)
        return [re]
      rescue StandardError => err
        return false, err
      end 
    end

  end  
end

