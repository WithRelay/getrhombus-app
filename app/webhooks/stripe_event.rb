class StripeEvent

  # Methods sending emails out to merchant/customers must be idempotent except for invoice failed
  def process_event(hash, type)
    @hash = hash[:data][:object] if hash[:data]
    @stripe_event_for = type
    self.send(string_method_name[hash[:type]]) if string_method_name[hash[:type]].present?
  end

  def subscription_trial_will_end
    @data = Subscription.includes(merchant_customer: [:customer]).find_by(stripe_subscription_id: @hash[:id])
    return unless @data

    # Email merchant of time left
    trial_days_left = ((@hash[:trial_end] - Time.current.utc.to_i) / 1.days.to_f).ceil
    # Free Trial Expiration Notice (11 days after sign-up)
    EmailingService.free_trial_expiration_notice(@data.customer) if trial_days_left == 3
    update_subscription_data
  end

  def customer_subscription_deleted
    @data = Subscription.includes(merchant_customer: [:customer, :merchant], plan: []).find_by(stripe_subscription_id: @hash[:id])
    return unless @data

    user = @data.customer
    TextingService.release_number(user.rhombus_number) if user.is_merchant? && user.rhombus_number.present?
    update_subscription_data

    # Email about cancellation
    options = cancelled_subscription_options(@data)
    EmailingService.cancelled_subscription(options)
    EmailingService.subscription_cancelled(options)

    # LEAVE THIS FOR LATER
    # subscribe merchant (rhombus platform saas customer) to next plan if present
    # subscribe_merchant_to_downgraded_plan if @data.merchant_customer.customer.is_merchant?
  end

  def cancelled_subscription_options(subscription)
    merchant = subscription.merchant
    cancelled_at =  DateTime.strptime(subscription.canceled_at.to_s, '%s').in_time_zone(merchant.time_zone)
    {
      merchant: merchant,
      customer: subscription.customer,
      plan_name: subscription.plan_name,
      currency: subscription.plan_currency,
      currency_symbol: '$',
      cancellation_date: cancelled_at.strftime('%B %d,%Y | %-I:%M%P'),
      amount: subscription.txn_amount
    }
  end


  # At the moment, Subscription only changes if a coupon is added.
  # Else to change a subscription, cancel and create a new one
  # It also notifies us of changes from trial to active
  # You generally don't want to notify merchants or users in this method
  def customer_subscription_updated
    @data = Subscription.includes(merchant_customer: [:merchant, :customer], plan: []).find_by(stripe_subscription_id: @hash[:id])
    return unless @data
    update_subscription_data
    # Email admin about update
    EmailingService.customer_subscription_updated(@data.merchant_customer.merchant, @data.plan_name, @data.id)
  end

  # Most fields aren't important but we can resave data
  def update_subscription_data
    # plan_id, user_id, team_id, coupon_id do not need to be set since they are immutable
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
    @data.total = @hash[:total]
    @data.subtotal = @hash[:subtotal]
    @data.tax = @hash[:tax]
    @data.tax_percent = @hash[:tax_percent]
    @data.application_fee = @hash[:application_fee] || 0
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
    setup_invoice_data
    # notify admin
    EmailingService.invoice_created(@data) if @merchant_customer
  end

  def setup_invoice_data
    # Ensure all these exists else it isnt ours. They should.
    key = (@stripe_event_for == 'platform') ? :platform_stripe_customer_id : :managed_stripe_customer_id
    @merchant_customer = MerchantCustomer.includes(:merchant).find_by(key => @hash[:customer])

    if @merchant_customer
      @data.team_id = @merchant_customer.merchant_id
      @data.customer_id = @merchant_customer.customer_id

      # update coupon_id
      if @hash[:discount].present?
        coupon = Coupon.find_by(stripe_coupon_id: @hash[:discount][:coupon][:id])
        @data.coupon_id = coupon.id if coupon
      end

      update_invoice_data
    end
  end

  # Handles connect and platform payments. Parameters are basically the same. So nothing special.
  def invoice_payment_succeeded
    # Invoice should already exist but if it doesn't, create a new one
    @data = Invoice.where(stripe_invoice_id: @hash[:id]).first_or_initialize
    setup_invoice_data
    team = @merchant_customer.try(:merchant)

    if team
      # retrieve charge details
      # test that charge is true
      charge = PaymentService.retrieve_charge(@hash[:charge], team) if @hash[:charge]
      charge = charge.try(:first)

      # a transaction should not already exist but we need to check if it does so we don't send out emails again
      txn = Transaction.where(txn_uri: charge.id).first_or_initialize if charge

      # for now, we have only one line for each invoice - the subscription
      @hash[:lines][:data].each do |l|
        if l[:type] == 'subscription'
          # find subscription
          sbtn = Subscription.includes(:plan).where(stripe_subscription_id: l[:id]).first

          # update subscription_id
          if sbtn && txn
            sbtn_fees = sbtn.get_fees
            app_fee = txn.app_fee.present? ? txn.app_fee : sbtn_fees[:app_fee]
            stripe_fee = txn.stripe_fee.present? ? txn.stripe_fee : sbtn_fees[:stripe_fee]
            description = txn.description.present? ? txn.description : sbtn.description

            # team@ should handle all transactions going forward
            # dashboard@ is only admin controls

            txn.update(
              amount: txn.amt_in_decimal(l[:amount]),
              app_fee: app_fee, stripe_fee: stripe_fee,
              amount_with_taxes: txn.amt_in_decimal(@hash[:total]),
              txn_number: txn.txn_number || txn.generate_txn_number,
              description: description,
              team_id: @data.team_id, user_id: @data.customer_id,
              hashtag_id: sbtn.plan.hashtag_id, txn_available_at: @hash[:date],
              tax_percent: @hash[:tax_percent],
              # At the moment, charge will only contain 1 line item, what if there are a couple line items?
              txn_uri: charge.id, currency: charge.currency,
              status: charge.status, last4: charge.source.last4,
              exp_month: charge.source.exp_month, exp_year: charge.source.exp_year,
              card_type: charge.source.brand, card_name: charge.source.name,
              subscription_id: sbtn.id, destination: charge.destination, captured: charge.captured
            )

            @data.update(transaction_id: txn.id, subscription_id: sbtn.id)
            # Notify customer (could be merchant)
            #EmailingService.invoice_payment_succeeded(@merchant_customer.customer)
            send_invoice_payment_succeeded_email if @data.team.is_platform?
          end
        end
      end
    end
  end

  def send_invoice_payment_succeeded_email
    merchant = @data.customer
    date = DateTime.strptime(@data.date.to_s, '%s').in_time_zone(merchant.time_zone)
    options = {
      month: Date::MONTHNAMES[Time.current.month],
      stripe_invoice_id: @data.stripe_invoice_id,
      date: date.strftime('%B %d,%Y | %-I:%M%P'),
      status: 'Invoice payment succeeded',
      payment_method: "Visa **** **** **** #{merchant.last4} (Expiry #{merchant.exp_month}/#{merchant.exp_year})",
      sub_total: @data.subtotal,
      total: @data.total,
      tax_and_fees: (@data.tax.to_f + @data.application_fee.to_f),
      currency: @data.currency,
      currency_symbol: '$',
      merchant: merchant
    }
    EmailingService.subscription_receipt(options)
  end

  def invoice_payment_failed
    # find invoice and update...invoice should already exist but if it doesn't, create a new one
    @data = Invoice.where(stripe_invoice_id: @hash[:id]).first_or_initialize
    setup_invoice_data
    # notify customer
    date = DateTime.strptime(@data.date.to_s, '%s').in_time_zone(@data.team.time_zone)
    options = {
      customer: @data.customer,
      merchant_business_name: @data.team.org_name,
      plan_name: @data.subscription.plan_name,
      currency: @data.currency,
      currency_symbol: '$',
      frequency: @data.subscription.plan_interval,
      failed_date: date.strftime('%B %d,%Y | %-I:%M%P'),
      amount: @data.total
    }
    EmailingService.subscription_failed(options)
  end

  # customer_source_updated webhook will fire if your customers’ info/customer's card info changes
  def customer_source_updated
    # customer source info/customer's card info
    @source = @hash[:data][:object]

    # find customer
    mc = MerchantCustomer.find_by(managed_stripe_customer_id: @source[:customer])
    mc = MerchantCustomer.find_by(platform_stripe_customer_id: @source[:customer]) unless mc

    if mc
      @data = mc.customer
      update_customer_source
      # find customer and admin
      # Notify them (admin) (customer)
      EmailingService.customer_source_updated(mc.customer, mc.merchant)
    end
  end

  def update_customer_source
    @data.last4 = @source[:last4]
    @data.card_id = @source[:id]
    @data.exp_month = @source[:exp_month]
    @data.exp_year = @source[:exp_year]
    @data.card_type = @source[:brand] if @source[:brand].present?
    @data.card_name = @source[:name] if @source[:name].present?
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

=begin
  # LEAVE THIS FOR LATER
  # Subscribe customer to next plan (downgrading plan)
  def subscribe_merchant_to_downgraded_plan
    if next_plan = NextPlan.where(user_id: @data.merchant_customer.customer_id, status: true).last
      subscription = Subscription.new(plan_id: next_plan.plan_id, merchant_customer_id: @data.merchant_customer.id)
      team = MerchantCustomer.find_by(customer_id: next_plan.user_id).customer
      res = subscription.create_subscription({team: team})
      next_plan.update(status: false) if res.first
    end
  end
=end

  def account_updated
    begin
      user_params = response_user_params.merge(bank_account_details)
      managed_account_user.update(user_params)
    rescue => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In StripeEvent account_updated",
                                                                            merchant: managed_account_user, data: @hash })
    end
  end

  def managed_account_user; @stripe_cred.user end

  def response_user_params
    @account = Stripe::Account.retrieve(@hash[:id])
    @stripe_cred = StripeCred.includes(:user).find_by_account_id(@hash[:id])
    {
      org_name: @hash[:business_name], url: @hash[:business_url],
      org_type: @hash[:legal_entity][:type].try(:capitalize),
      stripe_creds_attributes: {
                                  charges_enabled: @account[:charges_enabled],
                                  payouts_enabled: @account[:payouts_enabled],
                                  account_verification: @account.verification.to_hash,
                                  legal_entity_verification: @account.legal_entity.verification.to_hash,
                                  id: @stripe_cred.id
                               }
    }
  end

  def address_params
    @hash[:legal_entity][:address]
  end

  def bank_account_details
    bank_account_params = @account.external_accounts.data.first
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
      'customer.subscription.updated' => :customer_subscription_updated,
      # customer_source_updated webhook will fire if your customers’ info/customer's card info changes.
      'customer.source.updated' => :customer_source_updated,
      'invoice.payment_failed'=> :invoice_payment_failed,
      'invoice.payment_succeeded'=> :invoice_payment_succeeded,
      'invoice.created'=> :invoice_created,
      # 'invoice.updated'=> :invoice_updated,
      # when custom account information like external bank_account get updated
      'account.updated'=> :account_updated
    }
  end
  # We supply pretty much all data except for additional_owners and document
  # So that could be returned here in verification[:fields_needed]
  # legal_entity.additional_owners legal_entity.verification.document
  # legal_entity.additional_owners.#.verification.document (where # can be 0, 1, 2, or 3).
  # external_account

end
