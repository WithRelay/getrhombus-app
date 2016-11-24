class PaymentService

  class << self

    # Create or update customer on Stripe
    def add_token_to_stripe_customer(current_user, params)
      merchant_customer = (current_user.user_level == 0) ? current_user.customer.last : current_user.merchant.last
      if params[:card_token].present?
        begin
          if merchant_customer.stripe_customer_id.blank?   # Doesnt have a customer uri => first time
            cu = Stripe::Customer.create(email: current_user.email, source: params[:card_token])
            merchant_customer.update(stripe_customer_id: cu.id)
            current_user.livemode = cu.livemode
          else
            cu = Stripe::Customer.retrieve(merchant_customer.stripe_customer_id)
            cu.email = current_user.email
            cu.source = params[:card_token]
            cu.save
          end
          #buy_merchant_number if self.user_level == 1 && self.rn_type == nil
        rescue Stripe::CardError => e
          # Since it's a decline, Stripe::CardError will be caught
          err  = e.json_body[:error]
          owner = User.find_by(email: Rails.application.secrets.team_email)
          Message.send_and_save_message(owner.rhombus_number, current_user.phone_number, "We were unable to update your card info on Rhombus because: #{err[:message]}.")
          Notification.token_failure_notification(err, current_user.email).deliver_now
        rescue Stripe::StripeError => e
          Notification.token_failure_notification(e.json_body[:error], current_user.email).deliver_now
        rescue StandardError => e
          Notification.token_failure_notification(e, current_user.email).deliver_now
        end
        false
      end
      true
    end
    
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
      # using only customer_uri only since we support only 1 card and this
      # way if a customer changes the card on file we don't need to change the subscription source
      begin
        if platform
          re = Stripe::Subscription.create(hash)
        else
          tkn = Stripe::Token.create({ customer: hash[:customer] }, { stripe_account: stripe_account_uid })
          customer = Stripe::Customer.create({ source: tkn.id }, { stripe_account: stripe_account_uid })
          hash[:customer] = customer.id
          re = Stripe::Subscription.create(hash, { stripe_account: stripe_account_uid })
        end

        [true, re]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def cancel_subscription(subscription_id,stripe_account_uid, platform)
      begin
        res = if platform
          sbtn = Stripe::Subscription.retrieve(subscription_id)
          sbtn.delete(at_period_end: true) # cancel at period end
        else
          sbtn = Stripe::Subscription.retrieve(subscription_id, {stripe_account: stripe_account_uid})
          sbtn.delete(at_period_end: true) #cancel subscription immediately
        end
        [true, res]
      rescue Stripe::StripeError => e
        [false, e]
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
=end

