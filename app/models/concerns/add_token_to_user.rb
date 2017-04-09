module AddTokenToUser
  extend ActiveSupport::Concern

  # a merchant user who is a customer of platform
  # a customer user who is a customer of the platform and/or merchant(s) standalone and managed account
  # for merchant standalone account, it is a shared customer with the platform
  def add_token_for_user(card_token, send_decline_msg = true)
    #begin
      
      # platform acct shouldn't really be doing this
      return [true] if self.is_platform?
      
      hash = { email: self.email, card_token: card_token, new_customer: true, platform_customer: true } 
      
      # order so platform is first...platform generally have stripe customer id first
      merchant_customers = MerchantCustomer.where(customer_id: self.id).order(merchant_id: :asc)

      if merchant_customers.blank?            # This step doesn't really happen
        res = add_token_for_new_customer(hash) 
      else
        ### test, can i reuse the same token more than once??                                  
        platform_acct = User.get_platform_acct_obj
        merchant_customers.each do |mc|
          # can be on platform or merchant managed account. merchant is always on platform.
          is_platform = mc.merchant_id == platform_acct.id
          cred = mc.merchant.get_stripe_cred

          # we don't create customers on standalone accounts since we share platform customer with those
          if (is_platform && mc.platform_stripe_customer_id.blank?) || (!is_platform && cred[:type] == 'managed' && mc.managed_stripe_customer_id.blank?)
            res = add_token_for_customer_without_payment_info(mc, hash, is_platform, merchant_customers, cred)
          elsif (is_platform && mc.platform_stripe_customer_id.present?) || (!is_platform && cred[:type] == 'managed' && mc.managed_stripe_customer_id.present?)
            res = update_token_for_existing_customer(mc, hash, is_platform, merchant_customers, cred)
          else
            res = [true]
          end
          break unless res.first
        end
      end

      send_decline_text(res.third) if self.is_customer? && send_decline_msg && res.third
      res
    #rescue StandardError => e
      # notify team
     # [false]
    #end
  end

  # on platform only...also merchant not known 
  def add_token_for_new_customer(hash)
    platform_acct = User.get_platform_acct_obj
    res = PaymentService.add_token_to_stripe_customer(hash)
    if res.first
      # create new merchant_customer for stripe customer
      MerchantCustomer.create(merchant_id: platform_acct.id, customer_id: self.id, platform_stripe_customer_id: res.second.id)
    else
      # we are deleting customer in case customer was created but token wasn't added
      PaymentService.delete_customer(res.second.id, platform_acct.get_stripe_cred[:cred].account_id, true)
    end
    res
  end

  ### test, can i reuse the same token more than once??
  def add_token_for_customer_without_payment_info(mc, hash, is_platform, merchant_customers, cred)
    hash[:new_customer] = true
    hash[:platform_customer] = is_platform
        
    if is_platform
      res = PaymentService.add_token_to_stripe_customer(hash)
    else
      res = PaymentService.add_token_to_stripe_customer(hash, cred[:cred].account_id)
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
      PaymentService.delete_customer(res.second.id, cred[:cred].account_id, is_platform)
    end
    res
  end

  ### test, can i reuse the same token more than once??
  def update_token_for_existing_customer(mc, hash, is_platform, merchant_customers, cred)
    hash[:new_customer] = false
    hash[:platform_customer] = is_platform 
    hash[:stripe_customer_id] = is_platform ? mc.platform_stripe_customer_id : mc.managed_stripe_customer_id

    if is_platform
      res = PaymentService.add_token_to_stripe_customer(hash)
    else
      res = PaymentService.add_token_to_stripe_customer(hash, cred[:cred].account_id)
    end
    res
  end

  def send_decline_text(message)    
    platform_acct = User.get_platform_acct_obj
    msg_to_send = "We were unable to update your card info on Rhombus because: #{message}."
    Conversation.find_or_create_conversation_for_message_and_send_publish(platform_acct.rhombus_number, self, 'user', customer.id, msg_to_send, "Message")
  end

end
