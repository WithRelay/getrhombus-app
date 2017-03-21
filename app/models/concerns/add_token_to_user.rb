module AddTokenToUser
  extend ActiveSupport::Concern

  def add_token_to_user(card_token)
    begin
      # platform acct shouldn't really be doing this
      unless is_platform?
        res = []
        platform_acct = User.get_platform_acct_obj

        # Two scenarios
        # 1. a merchant user who is a customer of platform
        # 2. a customer user who is a customer of the platform and/or merchant(s)
        # Note that a customer user becomes a customer of merchant when a subscription is created

        cu = MerchantCustomer.where(customer_id: self.id)
        hash = { email: self.email, card_token: card_token, is_new_customer: true, is_platform_customer: true, is_merchant: is_merchant? }

        # when blank, add only to platform. Blank indicates signing up
        if cu.blank?
          re = PaymentService.add_token_to_stripe_customer(hash)
        else
          hash[:is_new_customer] = false
          if hash[:is_merchant]
            hash[:stripe_customer_id] = cu.first.stripe_customer_id
            # is merchant, so update on platform
            re = PaymentService.add_token_to_stripe_customer(hash)
          else
            cu.each do |c|
              hash[:stripe_customer_id] = c.stripe_customer_id
              # can be on platform or merchant (stripe managed) account
              hash[:is_platform_customer] = c.merchant_id == platform_acct.id
              if hash[:is_platform_customer]
                re = PaymentService.add_token_to_stripe_customer(hash)
              else
                re = PaymentService.add_token_to_stripe_customer(hash, get_stripe_cred.uid)
              end
            end
          end
        end

        # create new merchant_customer for stripe customer
        if cu.blank?
          if re.first
            MerchantCustomer.create(merchant_id: platform_acct.id, customer_id: self.id, stripe_customer_id: re[1].id)
          else
            # since new customer are always platform customer so is_platform is always true
            PaymentService.delete_customer(re[1].id, get_stripe_cred.uid, true)
          end
        end
        re
      else
        [true]
      end
    rescue StandardError => e
      # since new customer are always platform customer so is_platform is always true
      PaymentService.delete_customer(re[1].id, get_stripe_cred.uid, true) if (res.length > 0 && cu.blank?)
      # notify team
      [false]
    end
  end
end