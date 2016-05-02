class PaymentService

  Stripe.api_key = Rails.application.secrets.stripe["secret_key"]

  class << self
    
    def charge(amount_with_taxes, merchant, user, message)

      begin
        # Create the charge on Stripe's servers
        tkn = Stripe::Token.create(
              { :customer => user.customer_uri },
              merchant.stripe_access_token  # user's access token from the Stripe Connect flow
        )

        response = Stripe::Charge.create({
              :amount => amount_with_taxes, # in cents
              :currency => merchant.currency ? merchant.currency : "usd",
              :card => tkn.id,
              #:application_fee => rhombus_fee
              :description => "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.",
              :metadata => {
                "message" => message
              }            
            },
            merchant.stripe_access_token                    # merchants's access token from the Stripe Connect flow
        )

        return [response]
      rescue Stripe::CardError => e               # Since it's a decline, Stripe::CardError will be caught
        body = e.json_body
        err  = body[:error]
        # txn successful, error object, notify customer/merchant
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

