class PaymentService

  class << self

    # Create or update customer on Stripe
    def add_token_to_stripe_customer(hash, stripe_account_id = "")
      begin
        if hash[:is_new_customer]
          cu = Stripe::Customer.create(email: hash[:email], source: hash[:card_token])
        else 
          if hash[:is_platform_customer]
            cu = Stripe::Customer.retrieve(hash[:stripe_customer_id])
          else
            cu = Stripe::Customer.retrieve(hash[:stripe_customer_id], { stripe_account: stripe_account_id })
          end
          
          cu.email = hash[:email]
          cu.source = hash[:card_token]
          cu.save
        end
        return [true, cu]
      rescue Stripe::CardError => e
        # Since it's a decline, Stripe::CardError will be caught
        owner = User.find_by(email: Rails.application.secrets.team_email)
        unless hash[:is_merchant]
          customer = User.find_by(email: hash[:email])
          message = Message.new
          message.send_and_save_message(owner.rn_type, owner.rhombus_number, customer.phone_number, "We were unable to update your card info on Rhombus because: #{err[:message]}.")
        end
        # redo this email
        # Notification.token_failure_notification(err, hash[:email]).deliver_now
        [false, e, e.json_body[:error][:message]]
      rescue Stripe::StripeError => e
        # send this only to platform
        # Notification.token_failure_notification(e.json_body[:error], ....).deliver_now
        [false, e]
      rescue StandardError => e
        # send this only to platform
        #Notification.token_failure_notification(e, .....).deliver_now
        [false, e]
      end
    end

    def delete_customer(customer_id, stripe_account_id, is_platform)
      begin
        if is_platform
          cu = Stripe::Customer.retrieve(customer_id)
        else
          cu = Stripe::Customer.retrieve(customer_id, { stripe_account: stripe_account_id })
        end

        cu.delete
        [true]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end
    
    # return array with txn status, error object, notify customer/merchant
    def charge(amount_with_taxes, merchant, user, message, capture, platform=false)
      begin
        stripe_cred = merchant.get_stripe_cred

        if stripe_cred.standalone?                # need to backward support merchant's with standalone connect account
          # This also adds the customer to the connected account
          tkn = Stripe::Token.create({ customer: hash[:customer_uri] }, { stripe_account: stripe_account_id })
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
        [false, e, e.json_body[:error][:message], true]
      rescue Stripe::StripeError => e
        [false, e.json_body[:error], "Stripe error"]
      rescue StandardError => e
        [false, e, "Something went wrong"]
      end
    end

    # return array with txn status, error object, notify customer/merchant
    def process_captured_charge(charge_id)
      begin
        charge_ary = retrieve_charge(charge_id)       
        return charge_ary unless charge_ary[0]
        [charge_ary[1].capture]
      rescue Stripe::StripeError => e
        [false, e.json_body[:error], "Stripe is unable to process charge. Note that authorized txns over 7 days can no longer be processed."]
      rescue StandardError => e
        [false, e, "Something went wrong"]
      end
    end

    # returns array with refund status, error object
    def refund_charge(hash)
      begin
        ch = Stripe::Charge.retrieve(hash[:charge_id])
        re = ch.refunds.create(reason: hash[:reason], refund_application_fee: true, reverse_transfer: true)
        [true, re]
      rescue Stripe::StripeError => e
        # might need to specify that this is a stripe error
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    # must check that customer has a card on file first
    def create_subscription(hash, stripe_account_id, platform=false)
      # using only customer_uri only since we support only 1 card and this
      # way if a customer changes the card on file we don't need to change the subscription source
      begin
        if platform
          re = Stripe::Subscription.create(hash)
        else
          # is this where we create merchant-customer relationship?
          tkn = Stripe::Token.create({ customer: hash[:customer] }, { stripe_account: stripe_account_id })
          customer = Stripe::Customer.create({ source: tkn.id }, { stripe_account: stripe_account_id })
          hash[:customer] = customer.id
          re = Stripe::Subscription.create(hash, { stripe_account: stripe_account_id })
        end

        [true, re]
      rescue Stripe::CardError => e
        # Since it's a decline, Stripe::CardError will be caught
        [false, e, e.json_body[:error][:message]]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def cancel_subscription(subscription_id, stripe_account_id, platform, at_period_end)
      begin
        res = if platform
          sbtn = Stripe::Subscription.retrieve(subscription_id)
          sbtn.delete(at_period_end: at_period_end) # cancel at period end
        else
          sbtn = Stripe::Subscription.retrieve(subscription_id, { stripe_account: stripe_account_id })
          sbtn.delete(at_period_end: at_period_end)
        end
        [true, res]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def update_subscription(subscription_id, stripe_account_id, platform, coupon_id)
      begin
        if platform
          sbtn = Stripe::Subscription.retrieve(subscription_id)
          sbtn.coupon = coupon_id
        else
          sbtn = Stripe::Subscription.retrieve(subscription_id, { stripe_account: stripe_account_id })
          sbtn.coupon = coupon_id
        end
        sbtn.save
      rescue Stripe::StripeError => e
        false
      rescue StandardError => e
        false
      end
    end

    def create_plan(hash, stripe_account_id, platform)
      begin
        if platform
          p = Stripe::Plan.create(hash)
        else
          p = Stripe::Plan.create(hash, { stripe_account: stripe_account_id } )
        end
        [true, p]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def delete_plan(plan_id, stripe_account_id, platform)
      begin
        plan_id = plan_id.to_s
        if platform
          plan = Stripe::Plan.retrieve(plan_id)
        else
          plan = Stripe::Plan.retrieve(plan_id, { stripe_account: stripe_account_id })
        end
        plan.delete
        [true]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def update_plan(plan_id, hash, stripe_account_id, platform)
      begin
        plan_id = plan_id.to_s      
        if platform
          p = Stripe::Plan.retrieve(plan_id)
        else
          p = Stripe::Plan.retrieve(plan_id, { stripe_account: stripe_account_id })
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

    def is_valid_coupon(coupon_id)
      begin
        re = Stripe::Coupon.retrieve(coupon_id)
        re.valid
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        false
      rescue StandardError => e
        false
      end
    end
    
    def retrieve_charge(charge_id)
      begin
        re = Stripe::Charge.retrieve(charge_id)
        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error], "Stripe is unable to retrieve this charge."]
      rescue StandardError => e
        [false, e, "Something went wrong on our end"]
      end
    end

    # Some countries require that the routing num and institution num be concatenated with a specific character
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
