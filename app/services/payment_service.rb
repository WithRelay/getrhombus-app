class PaymentService

  class << self
    
    # return array with txn status, error object, notify customer/merchant
    def charge(amount_with_taxes, merchant, user, message, capture, platform=false)
      begin
        # This also add the customer to the connected account
        

        # need to backward support merchant's with old connect account
        if x          
          tkn = Stripe::Token.create({ customer: hash[:customer_uri] }, { stripe_account: stripe_account_uid })
          re = Stripe::Charge.create({
              amount: amount_with_taxes,
              currency: merchant.currency ? merchant.currency : "usd",
              source: tkn,
              capture: capture,
              description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last4}.",
              application_fee: 0,
              metadata: { "message" => message }  
            }, { stripe_account: hash[:uid] })
        else

          re = Stripe::Charge.create({
              amount: amount_with_taxes, # in cents
              currency: merchant.currency ? merchant.currency : "usd",
              customer: hash[:customer_uri],
              capture: capture,
              description: "Payment from #{user.email}. Card name: #{user.card_name}. Last four: #{user.last4}.",            
              
              # this should not be here for platform############
              destination: hash[:uid],    

              # statement_descriptor: '', # we will set this here
              # application_fee: rhombus_fee # from hash
              metadata: { "message" => message }            
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
    def refund_charge(charge_id, stripe_account_uid, platform=false)
      begin
        # need to check if i can refund transaction created prior to managed accounts    
        if platform
          ch = Stripe::Charge.retrieve(hash[:charge_id]) 
        else
          ch = Stripe::Charge.retrieve(hash[:charge_id], stripe_account: hash[:uid])
        end

        re = ch.refunds.create(refund_application_fee: true, reverse_transfer: true)
        [re]
      rescue Stripe::StripeError => e
        # might need to specify that this is a stripe error
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end 
    end

    # must check that customer has a card on file first
    def create_subscription(hash, stripe_account_uid, platform=false)
      begin
        if platform
          tkn = Stripe::Token.create({ customer: hash[:customer_uri] })
          hash[:source] = tkn
          re = Stripe::Subscription.create(hash)  
        else
          tkn = Stripe::Token.create({ customer: hash[:customer_uri] }, { stripe_account: stripe_account_uid })
          hash[:source] = tkn
          re = Stripe::Subscription.create(hash, { stripe_account: stripe_account_uid })  
        end

        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end
    
    def create_plan(hash, stripe_account_uid, platform)
      begin
        if platform
          p = Stripe::Plan.create(hash)
        else
          p = Stripe::Plan.create(hash, { stripe_account: stripe_account_uid } )
        end
        [true, p]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def delete_plan(plan_id, stripe_account_uid, platform)
      begin
        plan_id = plan_id.to_s
        if platform
          plan = Stripe::Plan.retrieve(plan_id)
        else
          plan = Stripe::Plan.retrieve(plan_id, { stripe_account: stripe_account_uid })
        end
        plan.delete
        [true]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def update_plan(plan_id, hash, stripe_account_uid, platform)
      begin
        plan_id = plan_id.to_s      
        if platform
          p = Stripe::Plan.retrieve(plan_id)
        else
          p = Stripe::Plan.retrieve(plan_id, { stripe_account: stripe_account_uid })
        end

        p.name = hash[:name]
        p.statement_descriptor = hash[:statement_descriptor]
        p.save

        [true]
      rescue Stripe::StripeError => e
        [false, e]
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

    def create_coupon(hash)
      begin
        # stripe_account param not needed for platform and only platform create coupons for now
        re = Stripe::Coupon.create(hash)
        [true, re]
      rescue Stripe::StripeError => e
        [false,  e]
      rescue StandardError => e
        [false, e]
      end
    end

    def delete_coupon(id)
      begin
        coupon = Stripe::Coupon.retrieve(id)
        coupon.delete
        [true]
      rescue Stripe::StripeError => e
        [false,  e]
      rescue StandardError => e
        [false, e]
      end
    end

    def create_managed_account(hash)
      begin
        re = Stripe::Account.create({ country: hash[:country], managed: true } )
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e]
      rescue StandardError => e
        [false, e]
      end

    end

    
    # Some countries require that the routing num and institition num be concatenated with a specific character
    # that's in index postion 1
    def stripe_country_list
      {
        AU: ["Australia",''], AT: ["Austria",''], BE: ["Belgium", ''], 
        CA: ["Canada", ''], DK: ["Denmark", ''], FI: ["Finland", ''], FR: ["France", ''],
        DE: ["Germany", ''], HK: ["Hong Kong", '-'], IE: ['Ireland', ''],
        IT: ['Italy', ''], LU: ['Luxembourg', ''], NL: ['Netherlands', ''], NO: ["Norway", ''],
        PT: ['Portugal', ''], SG: ['Singapore', '-'], #JP: 'Japan',
        ES: ["Spain", ''], SE: ["Sweden", ''], GB: ["United Kingdom", ''], US: ["United States", '']
      }
    end
      

  end  
end

=begin
    def create_customer(hash)
      cu = Stripe::Customer.create(email: hash[:email], source: hash[:card_token]) 
    end

    def update_customer(hash)
      cu = Stripe::Customer.retrieve(hash[:uri])  
      cu.email = hash[:email]
      cu.source = params[:card_token]
      cu.save   
    end
=end

