class StripeEvent
  #  Events

  #  managed accounts
  #  account.updated, account.external_account.created, account.external_account.updated

  #  subscriptions
  #  customer.subscription.trial_will_end, invoice.payment_failed, invoice.payment_succeeded

  #  For Later
  #  transfer.failed
  
  class << self

    # for customer.subscription.updated and is merchant...return twilio number etc??
    # or is this in deleted?

    def process_stripe_event(hash)
      @hash = hash
      case hash[:type]
      when "customer.subscription.trial_will_end"
        subscription_trial_will_end
      when "invoice.payment_failed"
        invoice_payment_failed
      when "invoice.payment_succeeded"
        invoice_payment_succeeded
      when "customer.subscription.deleted"
        customer_subscription_deleted
      end
    end


    def subscription_trial_will_end
      puts "\n\n\n"
      if subscription = Subscription.find_by(stripe_subscription_id: @hash[:data][:object][:id])
        @hash[:data][:object][:id]

      else
    end

    def invoice_payment_succeeded
    end

    def invoice_payment_failed
    end
    
    
  end



end
