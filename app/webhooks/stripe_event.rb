class StripeEvent
    
  class << self

    # Methods sending emails out must be idempotent except for invoice failed

    def process_stripe_event(hash)
      @hash = hash[:data][:object]
      puts JSON.pretty_generate(hash)
      case hash[:type]
      when "customer.subscription.trial_will_end"
        subscription_trial_will_end
      when "customer.subscription.deleted"
        customer_subscription_deleted
      when "customer.subscription.updated"
        customer_subscription_updated
      when "invoice.payment_failed"
        invoice_payment_failed
      when "invoice.payment_succeeded"
        invoice_payment_succeeded
      when "invoice.created"
        invoice_created
      when "invoice.updated"
        invoice_updated
      end
    end

    # So we can notify merchant of time left to active subscription
    def subscription_trial_will_end
      if @data = Subscription.find_by(stripe_subscription_id: @hash[:id])
        update_subscription_data

        # find merchant and admin
        # Email merchant of time left(merchant)
        # Notify us too (admin)
      end
    end

    # Add if deleted and merchant canceled account, return twilio number
    def customer_subscription_deleted
      if false #@data = Subscription.find_by(stripe_subscription_id: @hash[:id])
        # update_subscription_data
        
        # find merchant or user and admin
        # Email merchant of time left(merchant)????
        # Notify us too (admin)
      end
    end

    # At the moment, Subscription only changes if a coupon is added.
    # Else to change a subscription, cancel and create a new one
    # It also notifies us of changes from trial to active
    # You generally don't want to notify merchants or users in this method
    def customer_subscription_updated
      if false #@data = Subscription.find_by(stripe_subscription_id: @hash[:id])
        update_subscription_data
        # find admin
        # Notify (admin)
      end
    end

    # Most fields aren't important but we can resave data
    def update_subscription_data
      # plan_id, user_id, team_id, coupon_id do not need to be set since they are immutable
      @data.application_fee_percent = @hash[:application_fee_percent]
      @data.source = @hash[:source]
      @data.quantity = @hash[:quantity]
      @data.tax_percent = @hash[:tax_percent]
      @data.current_period_start = @hash[:current_period_start]
      @data.current_period_end = @hash[:current_period_end]
      @data.ended_at = @hash[:ended_at]
      @data.canceled_at = @hash[:canceled_at]
      @data.cancel_at_period_end = @hash[:cancel_at_period_end]
      @data.trial_start = @hash[:trial_start]
      @data.trial_end = @hash[:trial_end]
      @data.status = @hash[:status]
      @data.stripe_livemode = @hash[:stripe_livemode]
      @data.save
    end

    def update_invoice_data
      # plan_id, user_id, team_id, coupon_id, subscription_id do not need to be set since they are immutable
      
      @data.stripe_invoice_id = @hash[:stripe_invoice_id]

      @data.total = @hash[:total]
      @data.subtotal = @hash[:subtotal]
      @data.tax = @hash[:tax]
      @data.tax_percent = @hash[:tax_percent]
      @data.application_fee = @hash[:application_fee]
      @data.amount_due = @hash[:amount_due]
      @data.currency = @hash[:currency]

      @data.starting_balance = @hash[:starting_balance]
      @data.ending_balance = @hash[:ending_balance]
      @data.period_start = @hash[:period_start]
      @data.period_end = @hash[:period_end]
      @data.statement_descriptor = @hash[:statement_descriptor]
      
      @data.paid = @hash[:paid]
      @data.closed = @hash[:closed]
      @data.attempted = @hash[:attempted]
      @data.attempt_count = @hash[:attempt_count]
      @data.next_payment_attempt = @hash[:next_payment_attempt]
      @data.forgiven = @hash[:forgiven]
      @data.livemode = @hash[:livemode]

      @data.save
    end

    def invoice_created

      # invoice should not already exist but just in case stripe sends this multiple times
      @data = Invoice.where(stripe_invoice_id: @hash[:id]).first_or_initialize

      if user = User.find_by customer_uri: @hash[:customer]
        @data.user_id = user.id        

        if subscription = Subscription.includes(:team).where(stripe_subscription_id: @hash[:lines][:data][0][:id]).first
          @data.team_id = subscription.team_id
          set_time_zone(subscription.user.time_zone)
        end

        if @hash[:discount].present? && coupon = Coupon.find_by stripe_coupon_id: @hash[:discount][:coupon][:id]
          @data.coupon_id = coupon.id
        end

        update_invoice_data
      end

      # notify admin
    end

    # Handles connect and platform payments. Parameters are basically the same. So nothing special.
    def invoice_payment_succeeded

      # Invoice should already exist but if it doesn't, create a new one
      @data = Invoice.where(stripe_invoice_id: @hash[:id]).first_or_initialize
      
      # update_invoice_data
      update_invoice_data

      # retrieve charge details
      charge = Stripe::Charge.retrieve(@hash[:charge])  

      # a transaction should not already exist but we need to check if it does so we don't send out emails again
      txn = Transaction.includes(:notification_log).where(txn_uri: charge.id).first_or_initialize 

      # for now, we have only one line for each invoice - the subscription
      @hash[:lines][:data].each do |l|
        if l[:type] == 'subscription'
          
          # find subscription
          sbtn = Subscription.includes(:plan).includes(:team).where(stripe_subscription_id: l[:id]).first          
          
          amount_less_fees = 'calculate here'
          amount_with_taxes = 'calculate here'
          set_time_zone(sbtn.user.time_zone)          

          # team@ should handle all transactions going forward
          # dashboard@ is only admin controls

          txn.save( amount: l[:amount], currency: l[:currency], description: 'generate here',
                    rhombus_fee: l[:application_fee], user_id: sbtn.user_id, team_id: sbtn.team_id, 
                    hashtag_id: sbtn.plan.hashtag_id, txn_available_at: @hash[:date], 
                    # At the moment, charge will only contain 1 line item, what if there are a couple line items?
                    txn_uri: @hash[:charge], tax_percent: @hash[:tax_percent], amount_less_fees: amount_less_fees, 
                    amount_with_taxes: amount_with_taxes, txn_number: txn.generate_txn_number, 
                    status: 1, last_four: charge.source.last4, 
                    exp_month: charge.source.exp_month, exp_year: charge.source.exp_year,
                    card_type: charge.source.brand, card_name: charge.source.name,
                    destination: charge.destination, captured: charge.captured )
        end
      end

      # set transaction_id
      @data.update_attribute(:transaction_id, txn.id)
      
      # if we haven't notified customers before
      unless txn.notification_log
        # Notify customer and/or merchant
        # Notify (admin)      
        txn.notification_log = NotificationLog.create(notify_type: 'new_transaction', reason: 'receipt', channel: 'email')
      end
    end

    def set_time_zone(zone)
      Time.use_zone(zone)
    end

    def invoice_payment_failed
      # find invoice and update
      if false #@data = Invoice.find_by(stripe_invoice_id: @hash[:id])
        update_invoice_data
        # find customer and admin
        # Notify them (admin) (customer)
      end
    end

    # This really shouldn't occur since we currently don't allow invoices to be updated
    def invoice_updated
      # find invoice and update
      if false #@data = Invoice.find_by(stripe_invoice_id: @hash[:id])
        update_invoice_data
        # find admin
        # Notify (admin)
      end
    end
    
  end
end
