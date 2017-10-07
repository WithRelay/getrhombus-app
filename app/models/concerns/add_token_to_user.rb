module AddTokenToUser
  extend ActiveSupport::Concern

  # a merchant user who is a customer of platform
  # a customer user who is a customer of the platform and/or merchant(s) standalone and managed account
  # for merchant standalone account, it is a shared customer with the platform
  def add_token_for_user(card_token, send_decline_msg = true)
    begin
      
      # platform acct shouldn't really be doing this
      return [true] if self.is_platform?
      
      hash = { email: self.email, card_token: card_token, new_customer: true, platform_customer: true } 
      
      # order so platform is first
      merchant_customers = MerchantCustomer.includes(:merchant).where(customer_id: self.id).order(is_platform: :asc)

      # This step doesn't really happen anymore since merchant customer between platform and customer happens at sign up
      if merchant_customers.blank?            
        res = add_token_for_new_customer(hash) 
      else                                 
        is_platform, platform_customer = false, nil

        merchant_customers.each do |mc|
          cred = mc.merchant.get_stripe_cred  

          # can be on platform or merchant managed account. merchant is always on platform.
          if mc.merchant.is_platform?
            is_platform = true
            platform_customer = mc
          else
            platform_customer.reload if is_platform         # do it once
            is_platform = false
            hash[:card_token] = nil       # create new tokens for managed account since the js token from view is for platform
          end
          
          # we don't create customers on standalone accounts since we share platform customer with those
          if (is_platform && mc.platform_stripe_customer_id.blank?) || (!is_platform && cred[:type] == 'managed' && mc.managed_stripe_customer_id.blank?)
            puts 'asdasdas2222222222222222222222222222222'
            res = add_token_for_customer_without_payment_info(mc, hash, is_platform, cred, merchant_customers, platform_customer.platform_stripe_customer_id)
          elsif (is_platform && mc.platform_stripe_customer_id.present?) || (!is_platform && cred[:type] == 'managed' && mc.managed_stripe_customer_id.present?)
            res = update_token_for_existing_customer(mc, hash, is_platform, cred, platform_customer.platform_stripe_customer_id)
          else
            res = [true]
          end
          break unless res.first
        end
      end

      send_decline_text(res.third) if self.is_customer? && send_decline_msg && res.third
      res
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In add_token_for_user" })
      [false]
    end
  end

  # on platform only...also merchant not known 
  def add_token_for_new_customer(hash)
    res = PaymentService.add_token_to_stripe_customer(hash)
    if res.first
      # create new merchant_customer for stripe customer
      MerchantCustomer.create(merchant_id: User.get_platform_acct_obj.id, customer_id: self.id, platform_stripe_customer_id: res.second.id)
    else
      # we are deleting customer in case customer was created but token wasn't added
      PaymentService.delete_customer(res.second.id, '', true) if res.second.is_a?(Stripe::Customer)
    end
    res
  end

  def add_token_for_merchant_customer_from_platform_customer(mc)
    platform_customer = MerchantCustomer.includes(:customer).find_by(merchant_id: User.get_platform_acct_obj.id, customer_id: mc.customer_id)
    
    hash = { email: platform_customer.customer.email, card_token: nil, new_customer: true, platform_customer: false } 

    res = PaymentService.add_token_to_stripe_customer(hash, self.get_stripe_cred[:cred], platform_customer.platform_stripe_customer_id)
    if res.first
      mc.update(managed_stripe_customer_id: res.second.id, platform_stripe_customer_id: platform_customer.platform_stripe_customer_id)
    else
      # we are deleting customer in case customer was created but token wasn't added
      PaymentService.delete_customer(res.second.id, self.get_stripe_cred[:cred], false) if res.second.is_a?(Stripe::Customer)
    end
    res
  end

  def add_token_for_customer_without_payment_info(mc, hash, is_platform, cred, merchant_customers, platform_stripe_customer_id)
    hash[:new_customer] = true
    hash[:platform_customer] = is_platform
        
    if is_platform
      res = PaymentService.add_token_to_stripe_customer(hash)
    else
      res = PaymentService.add_token_to_stripe_customer(hash, cred[:cred], platform_stripe_customer_id)
    end
    
    # update merchant_customer info for stripe customer. either platform or managed accounts.
    if res.first
      if is_platform
        merchant_customers.update_all(platform_stripe_customer_id: res.second.id)
      else
        mc.update(managed_stripe_customer_id: res.second.id)
      end
    else
      # delete customer on the platform or merchant account in case customer was created but token wasn't added
      PaymentService.delete_customer(res.second.id, cred[:cred], is_platform) if res.second.is_a?(Stripe::Customer)
    end
    res
  end

  def update_token_for_existing_customer(mc, hash, is_platform, cred, platform_stripe_customer_id)
    hash[:new_customer] = false
    hash[:platform_customer] = is_platform 
    hash[:stripe_customer_id] = is_platform ? mc.platform_stripe_customer_id : mc.managed_stripe_customer_id

    if is_platform
      res = PaymentService.add_token_to_stripe_customer(hash)
    else
      res = PaymentService.add_token_to_stripe_customer(hash, cred[:cred].account_id, platform_stripe_customer_id)
    end
    res
  end

  def send_decline_text(message)
    msg_to_send = "We were unable to update your card info on Rhombus because: #{message}."
    Conversation.find_or_create_conversation_for_message_and_send_publish(User.get_platform_acct_obj.rhombus_number, self, 'user', customer.id, msg_to_send)
  end

end
