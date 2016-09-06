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
              application_fee: 0,
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
    def refund_charge(charge_id, stripe_account_uid)
      begin
        # need to check if i can refund transaction created prior to managed accounts    
        ch = Stripe::Charge.retrieve(charge_id, stripe_account: stripe_account_uid)
        re = ch.refunds.create(refund_application_fee: true, reverse_transfer: true)
        [re]
      rescue Stripe::StripeError => e
        # might need to specify that this is a stripe error
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end 
    end

    def create_subscription(hash, stripe_account_uid)
      begin
        re = Stripe::Subscription.create(hash, { stripe_account: stripe_account_uid })  
        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end
    
    def create_plan(hash, stripe_account_uid)
      begin
        # will calling it this way for rhombus itself work
       # re = Stripe::Plan.create(hash, { stripe_account: stripe_account_uid })  
        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    def cancel_subscription(hash)
      begin 
        sbtn = Stripe::Subscription.retrieve(hash[:subscription_id])
        sbtn.delete(at_period_end: hash[:at_period_end])
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    # This applies to saas fee only
    # so only coupon changes should call this for now
    # Stripe prorate charges by default
    def update_subscription(hash)
      begin 
        sbtn = Stripe::Subscription.retrieve(hash[:subscription_id])
        sbtn.coupon = hash[:stripe_coupon_id]
        sbtn.save
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    def create_coupon(hash, stripe_account_uid)
      begin
        # will calling it this way for rhombus itself work
        #re = Stripe::Coupon.create(hash, { stripe_account: stripe_account_uid })  
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

