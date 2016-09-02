class PaymentService

  class << self
    
    # return array with txn status, error object, notify customer/merchant
    def charge(amount_with_taxes, merchant, user, message, capture)
      begin

        # need to backward support merchant's with old connect account
        if x
          re = Stripe::Charge.create({
              amount: amount_with_taxes,
              currency: merchant.currency ? merchant.currency : "usd",
              source: user.instrument_uri,
              capture: capture,
              description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.",
              # application_fee: rhombus_fee
              metadata: {
                "message" => message
              }  
            }, { stripe_account: CONNECTED_STRIPE_ACCOUNT_ID })
        else
          re = Stripe::Charge.create({
            amount: amount_with_taxes, # in cents
            currency: merchant.currency ? merchant.currency : "usd",
            source: user.instrument_uri,
            capture: capture,
            description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last_four}.",
            
            #############
            destination: account_id,#merchant.stripe_access_token,
            # statement_descriptor: '',
            # application_fee: rhombus_fee
            metadata: {
              "message" => message
            }            
          })
        end

        [re]
      rescue Stripe::CardError => e               # Since it's a decline, Stripe::CardError will be caught
        [false, e.json_body[:error], true]
      rescue Stripe::StripeError => e
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    # returns array with refund status, error object
    def refund_charge(charge_id, CONNECTED_STRIPE_ACCOUNT_ID)
      begin
        # need to check if i can refund transaction created prior to managed accounts    
        ch = Stripe::Charge.retrieve(charge_id, stripe_account: CONNECTED_STRIPE_ACCOUNT_ID)
        re = ch.refunds.create(refund_application_fee: true, reverse_transfer: true)
        [re]
      rescue Stripe::StripeError => e
        # might need to specify that this is a stripe error
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end 
    end

    def create_subscription(hash, CONNECTED_STRIPE_ACCOUNT_ID)
      begin
        
        re = Stripe::Subscription.create(hash, { stripe_account: CONNECTED_STRIPE_ACCOUNT_ID })  
          #application_fee_percent: Rails.application.secrets.application_fee_percent,
          #coupon: hash[:coupon],
          #customer: "cus_8ePuK9YNuqOPgz", #hash[:customer]
          #plan: "quartz-unlimited-003", #hash[:plan]
          #source: hash[:source],
          #tax_percent: hash[:tax_percent],
        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end
    
    def create_plan(hash, CONNECTED_STRIPE_ACCOUNT_ID)
      begin
        # will calling it this way for rhombus itself work
        re = Stripe::Plan.create(hash, { stripe_account: CONNECTED_STRIPE_ACCOUNT_ID })  
          #amount: hash[:amt],
          #interval: hash[:interval],  
          #interval_count: hash[:count],  
          #name: "Ruby startup", # send hashtag here hash[:name]
          #currency: hash[:currency],
          #id: hash[:id], # send plan id in db here
          #statement_descriptor: hash[:statement_descriptor]
          #trial_period_days: hash[:trial_period_days]
        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    def cancel_subscription(subscription_id, at_period_end)
      begin 
        sub = Stripe::Subscription.retrieve(subscription_id)
        sub.delete(at_period_end: at_period_end)
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    def create_coupon(hash, CONNECTED_STRIPE_ACCOUNT_ID)
      begin
        # will calling it this way for rhombus itself work
        re = Stripe::Coupon.create(hash, { stripe_account: CONNECTED_STRIPE_ACCOUNT_ID })  
          #:percent_off => hash[:percent],
          #:duration => hash[:duration],
          #:duration_in_months => hash[:duration_in_months],
          #:id => '25OFF', #hash[:name]
        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    

  end  
end

