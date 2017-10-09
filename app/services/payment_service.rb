class PaymentService

  class << self

    # Create or update customer on Stripe
    def add_token_to_stripe_customer(hash, cred = {}, platform_stripe_customer_id = "")
      begin
        puts '<redacted_phone_number>'
        puts hash
        puts platform_stripe_customer_id
        puts '--------------------------------------'
        if hash[:card_token].blank?
          # platform should already have customer source at this point, it is only for a merchant that it can be blank
          # should be card_id here if customer has several card... but for now just the id works
          
          # token creation raises error if it fails
          # I believe this should be created off platform stripe customer id??? 
          hash[:card_token] = Stripe::Token.create({ customer: platform_stripe_customer_id },
                                                   { stripe_account: cred.account_id } ).id
        end

        if hash[:new_customer]
          if hash[:platform_customer]
            # create on platform
            cu = Stripe::Customer.create(email: hash[:email], source: hash[:card_token])
          else
            # create on managed account
            cu = Stripe::Customer.create({email: hash[:email], source: hash[:card_token]}, { stripe_account: cred.account_id })
          end
        else 
          if hash[:platform_customer]
            cu = Stripe::Customer.retrieve(hash[:stripe_customer_id])
          else
            cu = Stripe::Customer.retrieve(hash[:stripe_customer_id], { stripe_account: cred.account_id })
          end
          
          cu.email = hash[:email]
          cu.source = hash[:card_token]
          cu.save
        end
        puts 'asddddddddddddd'
        puts cu
        return [true, cu]
      rescue Stripe::CardError => e   # Since it's a decline, Stripe::CardError will be caught
        # redo this email
        # Notification.token_failure_notification(err, hash[:email]).deliver_now
        puts 'bbbbbbbbbbbbb'
        puts e.inspect
        [false, e, e.json_body[:error][:message]]
      rescue Stripe::StripeError => e
        # send this only to platform
        # Notification.token_failure_notification(e.json_body[:error], ....).deliver_now
        puts 'ccccccccccccccccccccccccccc'
        puts e.inspect
        [false, e]
      rescue StandardError => e
        # send this only to platform
        #Notification.token_failure_notification(e, .....).deliver_now
        puts 'ddddddddddddddddddddddddd'
        puts e.inspect
        [false, e]
      end
    end

    def delete_customer(customer_id, cred, is_platform)
      begin
        if is_platform
          cu = Stripe::Customer.retrieve(customer_id)
        else
          cu = Stripe::Customer.retrieve(customer_id, { stripe_account: cred.account_id })
        end

        cu.delete
        [true]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end
    
    def charge(amount_with_taxes, amt_less_fees, merchant, customer, msg, capture)
      #begin
        stripe_cred = merchant.get_stripe_cred
        currency = merchant.currency ? merchant.currency : "usd"

        # the platform always has a platform stripe_customer_id for a user making payment 
        merchant_customer = MerchantCustomer.find_by(merchant_id: User.get_platform_acct_obj.id, customer_id: customer.id)

        puts "putting stripe cred"
        puts stripe_cred

        # 1. need to backward support merchant's with standalone connect stripe_account
        # 2. platform account is identified as a standalone account. For charging merchants or regular customers. 
        # 3. managed accounts

        if stripe_cred[:type] == 'standalone'     
          unless merchant.is_platform?
            # token creation raises error if it fails
            token = Stripe::Token.create({ customer: merchant_customer.platform_stripe_customer_id },
                                         { stripe_account: stripe_cred[:cred].account_id } )

            re = Stripe::Charge.create({
              source: token.id,
              currency: currency,
              amount: amount_with_taxes, 
              metadata: { "message" => msg },              
              description: "Payment from #{customer.email}. Card name: #{customer.card_name}. Last four: #{customer.last4}.",
            }, { stripe_account: stripe_cred[:cred].account_id })
          else
            re = Stripe::Charge.create({
              capture: capture,
              currency: currency,
              amount: amount_with_taxes, 
              metadata: { "message" => msg },
              customer: merchant_customer.platform_stripe_customer_id,
              description: "Payment from #{customer.email}. Card name: #{customer.card_name}. Last four: #{customer.last4}.",
   ########!! statement_descriptor: '', # should already be on our stripe account, can still set this here...get from Edwin
            })
          end
        elsif stripe_cred[:type] == 'managed'         
          re = Stripe::Charge.create({
            capture: capture,
            currency: currency, 
            amount: amount_with_taxes,
            metadata: { "message" => msg },
            customer: merchant_customer.platform_stripe_customer_id,
            destination: {
              amount: amt_less_fees, 
              account: stripe_cred[:cred].account_id,
            }, 
            description: "Payment from #{customer.email}. Card name: #{customer.card_name}. Last four: #{customer.last4}.",
 ########!! statement_descriptor: '', # we will set this here...get from Edwin
          })
        end

        [re]
      #rescue Stripe::CardError => e               # Since it's a decline, Stripe::CardError will be caught
       # [false, e, e.json_body[:error][:message], true]
      # Stripe::InvalidRequestError (Amount must convert to at least 50 cents. 2.08 kr converts to approximately $0.26.)
      #rescue Stripe::StripeError => e
       # [false, e.json_body[:error], "Stripe error"]
      #rescue StandardError => e
       # [false, e, "Something went wrong"]
      #end
    end

    # return array with txn status, error object, notify customer/merchant
    def capture_charge(charge_id, merchant)
      begin
        charge_ary = retrieve_charge(charge_id, merchant)  
        return charge_ary unless charge_ary.first
        [charge_ary.first.capture]
      rescue Stripe::StripeError => e
        [false, e.json_body[:error], "Stripe is unable to process charge. Note that authorized txns over 7 days can no longer be processed."]
      rescue StandardError => e
        [false, e, "Sorry, we were unable to complete this transaction. Please try again later."]
      end
    end

    # returns array with refund status, error object
    def refund_charge(hash, merchant)
      begin
        cred = merchant.get_stripe_cred
        if merchant.is_platform? || cred[:type] == 'managed'
          # are the last two attrs ok for platform charges?
          re = Stripe::Refund.create(charge: hash[:charge_id], reason: hash[:reason], refund_application_fee: true, reverse_transfer: true)
        else
          re = Stripe::Refund.create({ charge: hash[:charge_id], reason: hash[:reason], 
                                       refund_application_fee: true, reverse_transfer: true }, 
                                       { stripe_account: cred[:cred].account_id })
        end
        [re]
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send yourself an email
        [false, e.json_body[:error]]
      rescue StandardError => e
        [false, e]
      end
    end

    # note you should check that customer has card on file before calling this method
    def create_subscription(hash, cred, platform=false)
      # using only customer_uri since we support only 1 card and this
      # way if a customer changes the card on file we don't need to change the subscription source

      begin
        if platform
          re = Stripe::Subscription.create(hash)
        else
          re = Stripe::Subscription.create(hash, { stripe_account: cred.account_id })
        end

        [true, re]
      rescue Stripe::CardError => exception
        ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "From create_subscription"})
        # Since it's a decline, Stripe::CardError will be caught
        [false, exception, exception.json_body[:error][:message]]
      rescue Stripe::StripeError => exception
        ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "From create_subscription"})
        [false, exception]
      rescue StandardError => exception
        ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "From create_subscription"})
        [false, exception]
      end
    end

    def cancel_subscription(subscription_id, cred, platform, at_period_end)
      begin
        res = if platform
          sbtn = Stripe::Subscription.retrieve(subscription_id)
          sbtn.delete(at_period_end: at_period_end) # cancel at period end
        else
          sbtn = Stripe::Subscription.retrieve(subscription_id, { stripe_account: cred.account_id })
          sbtn.delete(at_period_end: at_period_end)
        end
        [true, res]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def update_subscription(subscription_id, cred, platform, coupon_id)
      begin
        if platform
          sbtn = Stripe::Subscription.retrieve(subscription_id)
          sbtn.coupon = coupon_id
        else
          sbtn = Stripe::Subscription.retrieve(subscription_id, { stripe_account: cred.account_id })
          sbtn.coupon = coupon_id
        end
        sbtn.save
      rescue Stripe::StripeError => e
        false
      rescue StandardError => e
        false
      end
    end

    def create_plan(hash, cred, platform)
      begin
        if platform
          p = Stripe::Plan.create(hash)
        else
          p = Stripe::Plan.create(hash, { stripe_account: cred.account_id } )
        end
        [true, p]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def delete_plan(plan_id, cred, platform)
      begin
        plan_id = plan_id.to_s
        if platform
          plan = Stripe::Plan.retrieve(plan_id)
        else
          plan = Stripe::Plan.retrieve(plan_id, { stripe_account: cred.account_id })
        end
        plan.delete
        [true]
      rescue Stripe::StripeError => e
        [false, e]
      rescue StandardError => e
        [false, e]
      end
    end

    def update_plan(plan_id, hash, cred, platform)
      begin
        plan_id = plan_id.to_s      
        if platform
          p = Stripe::Plan.retrieve(plan_id)
        else
          p = Stripe::Plan.retrieve(plan_id, { stripe_account: cred.account_id })
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

    def update_coupon(hash)
      begin
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
    
    def retrieve_charge(charge_id, merchant)
      begin
        cred = merchant.get_stripe_cred
        if merchant.is_platform? || cred[:type] == 'managed'
          re = Stripe::Charge.retrieve(charge_id)
        else
          re = Stripe::Charge.retrieve(charge_id, { stripe_account: cred[:cred].account_id })
        end
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
        #AU: ["Australia",''], AT: ["Austria",''], BE: ["Belgium", ''], 
        CA: ["Canada", ''], 
        #DK: ["Denmark", ''], FI: ["Finland", ''], FR: ["France", ''],
        #DE: ["Germany", ''], HK: ["Hong Kong", '-'], IE: ['Ireland', ''],
        #IT: ['Italy', ''], LU: ['Luxembourg', ''], NL: ['Netherlands', ''], NO: ["Norway", ''],
        #PT: ['Portugal', ''], SG: ['Singapore', '-'], #JP: 'Japan',
        #ES: ["Spain", ''], SE: ["Sweden", ''], GB: ["United Kingdom", ''], 
        US: ["United States", '']
      }
    end
  end
end
