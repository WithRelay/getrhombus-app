class StripeEvent

  class << self
    # Methods sending emails out to merchant/customers must be idempotent except for invoice failed

    def process_event(hash)
      @hash = hash[:data][:object] if hash[:data]
      # send works like message passing to class hierarchy until method reacts
      # it accepts a parameter that need to be pass in symbol or string which calls method.
      # if we pass string it will internally converts to symbol.
      self.send(string_method_name[hash[:type]]) if string_method_name[hash[:type]].present?
    end

    # So we can notify merchant of time left to active subscription
    def subscription_trial_will_end
      # if @data = Subscription.includes(:notification_log).includes(:team)
      if @data = Subscription.includes(:notification_logs)
                        .where(stripe_subscription_id: @hash[:id]).first
                        # .where("stripe_subscription_id = ? and notify_type = ?", @hash[:id], 'subscription_trial_will_end').first
        # set_time_zone(@data.merchant_customer.merchant.time_zone)
        update_subscription_data
        
        # Email merchant of time left(merchant)
        # Notify us too (admin)
        @data.notification_logs << NotificationLog.create(notify_type: 'subscription_trial_will_end', channel: 'email', reason: 'Subscription trial is about to end.')
      end
    end

    # Add if deleted and merchant canceled account, return twilio number
    def customer_subscription_deleted
      if @data = Subscription.includes(:notification_logs)
                      .where(stripe_subscription_id: @hash[:id]).first
                      # .where("stripe_subscription_id = ? and notify_type = ?", @hash[:id], 'subscription_deleted').first

        # set_time_zone(@data.merchant_customer.merchant.time_zone)
        update_subscription_data if @data
        
        # subscribe merchant (rhombus platform saas customer) to next plan if present
        subscribe_merchant_to_downgraded_plan if @data.merchant_customer.customer.is_merchant?  

        # Email about cancellation
        # Notify us too (admin)
        @data.notification_logs << NotificationLog.create(notify_type: 'subscription_deleted', channel: 'email', reason: 'Subscription has been deleted.')
      end
    end

=begin
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
=end

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
      @data.stripe_livemode = @hash[:livemode]
      @data.save
    end

    def update_invoice_data
      # user_id, team_id, coupon_id, subscription_id do not need to be set since they are immutable
      @data.date = @hash[:date]
      @data.stripe_invoice_id = @hash[:id]

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

      # Ensure all these exists else it isnt ours. They should.
      merchant_customer = MerchantCustomer.find_by(stripe_customer_id:  @hash[:customer])
      if merchant_customer
        # update merchant_customer
        @data.merchant_customer_id = merchant_customer.id

        # update coupon_id
        if @hash[:discount].present? && coupon = Coupon.find_by(stripe_coupon_id: @hash[:discount][:coupon][:id])
          @data.coupon_id = coupon.id
        end
        # update invoice data
        update_invoice_data
      end
      # notify admin
    end

    # Handles connect and platform payments. Parameters are basically the same. So nothing special.
    def invoice_payment_succeeded
      # Invoice should already exist but if it doesn't, create a new one
      @data = Invoice.includes(:notification_log).where(stripe_invoice_id: @hash[:id]).first_or_initialize
      # update_invoice_data
      update_invoice_data

      # retrieve charge details
      charge = PaymentService.retrieve_charge(@hash[:charge]) if @hash[:charge] 
      # a transaction should not already exist but we need to check if it does so we don't send out emails again
      # A tranasaction has only one log unlike subscriptions
      txn = Transaction.includes(:notification_logs).where(txn_uri: charge.id).first_or_initialize if charge

      # if we havent notified customer before
      # for now, we have only one line for each invoice - the subscription
      @hash[:lines][:data].each do |l|
        if l[:type] == 'subscription'
          # find subscription
          sbtn = Subscription.includes(:plan).where(stripe_subscription_id: l[:id]).first
          # update subscription_id
          if sbtn
            @data.update(subscription_id: sbtn.id)
            hashtag_id = sbtn.plan.hashtag_id
            sbtn_id = sbtn.id
          end

          if txn
            # just in case transaction actually exists but not log
            amount_less_fees = txn.amount_less_fees ? txn.amount_less_fees : 'calculate here'
            amount_with_taxes = txn.amount_with_taxes ? txn.amount_with_taxes : 'calculate here'
            txn_number = txn.txn_number ? txn.txn_number : txn.generate_txn_number
            description = description ? txn.description : "generate here"

            # team@ should handle all transactions going forward
            # dashboard@ is only admin controls

            txn.update( amount: l[:amount], currency: l[:currency], description: description,
              application_fee: l[:application_fee],
              merchant_customer_id: @data.merchant_customer_id,
              hashtag_id: hashtag_id, txn_available_at: @hash[:date],
              # At the moment, charge will only contain 1 line item, what if there are a couple line items?
              txn_uri: @hash[:charge], tax_percent: @hash[:tax_percent], amount_less_fees: amount_less_fees,
              amount_with_taxes: amount_with_taxes, txn_number: txn_number,
              status: 1, last4: charge.source.last4,
              exp_month: charge.source.exp_month, exp_year: charge.source.exp_year,
              card_type: charge.source.brand, card_name: charge.source.name,
              subscription_id: sbtn_id, destination: charge.destination, captured: charge.captured
            )

            # set transaction_id
            @data.update_attribute(:transaction_id, txn.id)
            # Notify customer and/or merchant
            # Notify (admin)

            txn.notification_logs << NotificationLog.create(notify_type: 'new_transaction', reason: 'receipt', channel: 'email')
          end
        end
      end
      # save invoice_payment_succeeded event responce to notification_log
      if @data
        @data.notification_log = NotificationLog.create(notify_type: 'invoice_payment_succeeded', channel: 'email', reason: 'Invoice payment has been succeeded.')
      end
    end

    def set_time_zone(zone)
      Time.use_zone(zone)
    end

    def invoice_payment_failed
      # find invoice and update
      @data = Invoice.includes(:notification_log).where(stripe_invoice_id: @hash[:id]).first_or_initialize #Invoice should already exist but if it doesn't, create a new one
      update_invoice_data
      # find customer and admin
      # Notify them (admin) (customer)
      if @data
        @data.notification_log =  NotificationLog.create(notify_type: 'invoice_payment_failed', channel: 'email', reason: 'Invoice payment has been failed.')
      end
    end

    # customer_source_updated webhook will fire if your customers’ info/customer's card info changes
    def customer_source_updated
      # customer source info/customer's card info
      @source = @hash[:data][:object]
      # find customer
      merchant_customer = MerchantCustomer.find_by(stripe_customer_id: @source[:customer])
      @data = User.find merchant_customer.customer_id
      update_customer_source
      # find customer and admin
      # Notify them (admin) (customer)
      # update notification log if we need it
    end

    def update_customer_source
      @data.last4 = @source[:last4]
      @data.exp_month = @source[:exp_month]
      @data.exp_year = @source[:exp_year]
      @data.card_name = @source[:name]
      @data.card_type = @source[:type]
      @data.save
    end

    # This really shouldn't occur since we currently don't allow invoices to be updated
    # def invoice_updated
    #   # find invoice and update
    #   if false #@data = Invoice.find_by(stripe_invoice_id: @hash[:id])
    #     update_invoice_data
    #     # find admin
    #     # Notify (admin)
    #   end
    # end

    private
    # Subscribe customer to next plan (downgrading plan)
    def subscribe_merchant_to_downgraded_plan
      if next_plan = NextPlan.where(user_id: @data.merchant_customer.customer_id, status: true).last
        subscription = Subscription.new(plan_id: next_plan.plan_id, merchant_customer_id: @data.merchant_customer.id)
        team = MerchantCustomer.find_by(customer_id: next_plan.user_id).customer
        res = subscription.create_subscription({team: team})
        next_plan.update(status: false) if res.first
      end
    end

    def account_updated
      user_params = response_user_params.merge(bank_accont_params)
      managed_accout_user.update(user_params)
    rescue => e
    end

    def managed_accout_user; StripeCred.find_by_account_id(@hash[:id]).user end

    def response_user_params
      account = Stripe::Account.retrieve(@hash[:id])
      {
        org_name: @hash[:business_name], url: @hash[:business_url],
        org_type: bank_account_params[:account_holder_type],
        address_attributes: { street_address: address_params[:street], city: address_params[:city],
                              state_province: address_params[:state],
                              country: address_params[:country], postal_code: address_params[:zip] },
        stripe_creds_attributes: { fields_needed: account.verification.fields_needed }
      }
    end

    def bank_account_params
      @hash[:external_accounts][:data][0]
    end

    def address_params
      @hash[:address]
    end

    def bank_accont_params
      bank_account = BankAccount.find_by_stripe_bank_account_id(bank_account_params[:id])
      bank_account_details = {}
      bank_account_details[:bank_accounts_attributes] = { country: bank_account_params[:country],
                                                          routing_number: bank_account_params[:routing_number],
                                                          currency: bank_account_params[:currency],
                                                          bank_name: bank_account_params[:name],
                                                          status: bank_account_params[:status],
                                                          fingerprint: bank_account_params[:fingerprint],
                                                          stripe_bank_account_id: bank_account_params[:id],
                                                          id: bank_account.id
                                                        }
      bank_account_details
    end

    def string_method_name
      {
        'customer.subscription.trial_will_end'=> :subscription_trial_will_end,
        'customer.subscription.deleted'=> :customer_subscription_deleted,
        # customer_source_updated webhook will fire if your customers’ info/customer's card info changes.
        'customer.source.updated' => :customer_source_updated,
        'invoice.payment_failed'=> :invoice_payment_failed,
        'invoice.payment_succeeded'=> :invoice_payment_succeeded,
        'invoice.created'=> :invoice_created,
        # 'invoice.updated'=> :invoice_updated,
        # when managed account information like external bank_account get updated
        'account.updated'=> :account_updated
      }
    end
    # We supply pretty much all data except for additional_owners and document
    # So that could be returned here in verification[:fields_needed]
    # legal_entity.additional_owners legal_entity.verification.document
    # legal_entity.additional_owners.#.verification.document (where # can be 0, 1, 2, or 3).
    # external_account
  end
end
