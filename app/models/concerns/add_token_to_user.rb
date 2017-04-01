module AddTokenToUser
  extend ActiveSupport::Concern

  # a merchant user who is a customer of platform
  # a customer user who is a customer of the platform and/or merchant(s)
  # Note that a customer user becomes a customer of merchant when a subscription/charge is created
  def add_token_for_user(card_token)
    begin
      # platform acct shouldn't really be doing this
      unless is_platform?
        res = []
        platform_acct = User.get_platform_acct_obj
        hash = { email: self.email, card_token: card_token, is_new_customer: true, 
                  is_platform_customer: true, is_merchant: self.is_merchant? } 
        cu = MerchantCustomer.where(customer_id: self.id)

        # when blank, add only to platform. blank indicates signing up
        if cu.blank?
          res = PaymentService.add_token_to_stripe_customer(hash)
        else
          hash[:is_new_customer] = false

          ### test, can i reuse the same token more than once??
          cu.each do |c|
            hash[:stripe_customer_id] = c.stripe_customer_id
            # can be on platform (legacy or from v1.5) or merchant (managed) account
            # merchant is always platform_customer
            hash[:is_platform_customer] = c.merchant_id == platform_acct.id
            if hash[:is_platform_customer]
              res = PaymentService.add_token_to_stripe_customer(hash)
            else
              res = PaymentService.add_token_to_stripe_customer(hash, c.merchant.get_stripe_cred[:cred].account_id)
            end
            break unless res.first
          end
        end

        # create new merchant_customer for stripe customer
        if cu.blank?
          if res.first
            MerchantCustomer.create(merchant_id: platform_acct.id, customer_id: self.id, stripe_customer_id: res[1].id)
          else
            # since a merchant is always a platform customer, so send in true
            # we are deleting customer in case customer was created but token wasn't added
            PaymentService.delete_customer(res[1].id, platform_acct.get_stripe_cred[:cred].account_id, true)
          end
        end
        res
      else
        [true]
      end
    rescue StandardError => e
      # always a platform customer the first time, so send in true
      # we are deleting customer in case customer was created but token wasn't added
      # cu.blank? ... delete only if customer didn't exists before... 
      if (res.length > 0 && cu.blank?)
        PaymentService.delete_customer(res[1].id, platform_acct.get_stripe_cred[:cred].account_id, true) 
      end
      # notify team
      [false]
    end
  end

  def add_token_for_new_customer(hash)
    res = PaymentService.add_token_to_stripe_customer(hash)
    if res.first
      MerchantCustomer.create(merchant_id: platform_acct.id, customer_id: self.id, stripe_customer_id: res[1].id)
    else
      # since a merchant is always a platform customer, so send in true
      # we are deleting customer in case customer was created but token wasn't added
      PaymentService.delete_customer(res[1].id, platform_acct.get_stripe_cred[:cred].account_id, true)
    end
    res
  end

  def add_token_for_customer_without_payment_info(hash)
    cu.each do |c|
      hash[:stripe_customer_id] = c.stripe_customer_id
      hash[:is_platform_customer] = c.merchant_id == platform_acct.id
      if hash[:is_platform_customer]
        res = PaymentService.add_token_to_stripe_customer(hash)
      else
        res = PaymentService.add_token_to_stripe_customer(hash, c.merchant.get_stripe_cred[:cred].account_id)
      end
      cu.update(:stripe_customer_id
      break unless res.first
    end
    res
  end

  def update_token_for_existing_customer
  end

end