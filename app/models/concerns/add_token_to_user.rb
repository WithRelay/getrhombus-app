module AddTokenToUser
  extend ActiveSupport::Concern

  # a merchant user who is a customer of platform
  def add_token_for_merchant(card_token)
    begin
      # platform acct shouldn't really be doing this
      unless is_platform?
        res = []
        platform_acct = User.get_platform_acct_obj

        cu = MerchantCustomer.where(customer_id: self.id, merchant_id: platform_acct.id).first
        hash = { email: self.email, card_token: card_token, is_new_customer: true, 
                  is_platform_customer: true, is_merchant: self.is_merchant? } 

        # when blank, add only to platform. blank indicates signing up
        if cu.blank?
          res = PaymentService.add_token_to_stripe_customer(hash)
        else
          hash[:is_new_customer] = false

          if cu.present?
            ### test, can i reuse the same token more than once??
            cu.each do |c|
              hash[:stripe_customer_id] = c.stripe_customer_id
              # can be on platform (legacy or from v1.5) or merchant (managed) account
              hash[:is_platform_customer] = c.merchant_id == platform_acct.id
              if hash[:is_platform_customer]
                res = PaymentService.add_token_to_stripe_customer(hash)
              else
                res = PaymentService.add_token_to_stripe_customer(hash, c.merchant.get_stripe_cred[:cred].account_id)
              end
              break unless res.first
            end
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

  # a customer user who is a customer of the platform and/or merchant(s)
  # Note that a customer user becomes a customer of merchant when a subscription is created
  def add_token_for_customer(card_token)
    begin
      res = []
      platform_acct = User.get_platform_acct_obj

      cu = MerchantCustomer.includes(:merchant).where(customer_id: self.id)
#      cu_standalone = StandaloneMerchantCustomer.where(customer_id: self.id)   # legacy
#      cu = cu_managed + cu_standalone

      hash = { email: self.email, card_token: card_token, is_new_customer: true, 
                is_platform_customer: true, is_merchant: false }

      # when blank, add only to platform. blank indicates signing up
      if cu.blank?
        res = PaymentService.add_token_to_stripe_customer(hash)
      else
        hash[:is_new_customer] = false

        if cu.present?
          ### test, can i reuse the same token more than once??
          cu.each do |c|
            hash[:stripe_customer_id] = c.stripe_customer_id
            # can be on platform (legacy or from v1.5) or merchant (managed) account
            hash[:is_platform_customer] = c.merchant_id == platform_acct.id
            if hash[:is_platform_customer]
              res = PaymentService.add_token_to_stripe_customer(hash)
            else
              res = PaymentService.add_token_to_stripe_customer(hash, c.merchant.get_stripe_cred[:cred].account_id)
            end
            break unless res.first
          end
        end
      end

      # create new merchant_customer for stripe customer
      if cu.blank?
        if res.first
          MerchantCustomer.create(merchant_id: platform_acct.id, customer_id: self.id, stripe_customer_id: res[1].id)
          #if cu_standalone.present?
           # StandaloneMerchantCustomer.create(merchant_id: platform_acct.id, customer_id: self.id, stripe_customer_id: res[1].id)
          #end
        else
          # since new customer are always platform customer so is_platform is always true
          PaymentService.delete_customer(res[1].id, platform_acct.get_stripe_cred[:cred].account_id, true)
        end
      end
      res
    rescue StandardError => e
      # since new customer are always platform customer so is_platform is always true
      if (res.length > 0 && cu.blank?)
        PaymentService.delete_customer(res[1].id, platform_acct.get_stripe_cred[:cred].account_id, true) 
      end
      # notify team
      [false]
    end

  end


  # a merchant user who is a customer of platform
  def add_token_for_merchant(card_token)
    begin
      # platform acct shouldn't really be doing this
      unless is_platform?
        res = []
        platform_acct = User.get_platform_acct_obj

        cu = MerchantCustomer.where(customer_id: self.id, merchant_id: platform_acct.id).first
        hash = { email: self.email, card_token: card_token, is_new_customer: true, 
                  is_platform_customer: true, is_merchant: true }

        if cu.present?
          hash[:is_new_customer] = false
          hash[:stripe_customer_id] = cu.stripe_customer_id 
        end
 
        # is merchant, so use platform
        res = PaymentService.add_token_to_stripe_customer(hash)

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
      # since a merchant is always a platform customer, so send in true
      # we are deleting customer in case customer was created but token wasn't added
      # cu.blank? ... delete only if customer didn't exists before... 
      if (res.length > 0 && cu.blank?)
        PaymentService.delete_customer(res[1].id, platform_acct.get_stripe_cred[:cred].account_id, true) 
      end
      # notify team
      [false]
    end
  end


end