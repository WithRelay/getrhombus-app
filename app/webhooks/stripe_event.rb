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
    if user.is_merchant?
      if user.rhombus_number.present?
        user.hosted_sms.blank? ? TextingService.release_number(user.rhombus_number) : ''
      end
      user.update(rhombus_number: nil, rn_type: nil, rn_country: nil, rn_friendly_name: nil, status: 0)
      #delete facebook integration here
      EmailingService.exit_survey(user)
    end
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
    cancelled_at = DateTime.strptime(subscription.canceled_at.to_s, '%s').in_time_zone(merchant.time_zone)
    {
      merchant: merchant,
      customer: subscription.customer,
      plan_name: subscription.plan_name,
      currency: subscription.plan_currency,
      currency_symbol: '$',
      cancellation_date: cancelled_at.strftime('%B %d, %Y | %-I:%M%P'),
      amount: subscription.txn_amount
    }
  end


  # At the moment, Subscription only changes if a coupon is added.
  # Else to change a subscription, cancel and create a new one
  # It also notifies us of changes from trial to active
  # You generally don't want to notify merchants or users in this method
  def customer_subscription_updated
    @data = Subscription.includes(:plan).find_by(stripe_subscription_id: @hash[:id])
    return unless @data
    update_subscription_data
    # Email admin about update
    EmailingService.customer_subscription_updated(@data.plan_name, @data.id)
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
    @merchant_customer = MerchantCustomer.includes(:merchant, :customer).find_by(key => @hash[:customer])

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
    # stripe doesnt guarantee invoice event order
    @data = Invoice.where(stripe_invoice_id: @hash[:id]).first_or_initialize
    setup_invoice_data
    @team = @merchant_customer.try(:merchant)
    @customer = @merchant_customer.customer

    if @team
      # retrieve charge details. test that charge exist. it doesnt exist for trialing subs
      charge = PaymentService.retrieve_charge(@hash[:charge], @team) if @hash[:charge]
      charge = charge.try(:first)

      # a transaction should not already exist but we need to check if it does so we don't send out emails again
      @txn = Transaction.where(txn_uri: charge.id).first_or_initialize if charge

      # for now, we have only one line for each invoice - the subscription
      @hash[:lines][:data].each do |l|
        if l[:type] == 'subscription'

          @sbtn = Subscription.includes(:plan).where(stripe_subscription_id: l[:id]).first
          if @sbtn && @txn
            @txn.update(
              amount: @txn.amt_in_decimal(l[:amount]),
              app_fee: @hash[:application_fee], stripe_fee: @sbtn.get_fees[:stripe_fee],
              amount_with_taxes: @txn.amt_in_decimal(@hash[:total]),
              txn_number: @txn.txn_number || @txn.generate_txn_number,
              description: @txn.description.present? ? @txn.description : @sbtn.description,
              team_id: @data.team_id, user_id: @data.customer_id,
              hashtag_id: @sbtn.plan.hashtag_id, txn_available_at: @hash[:date],
              transaction_fee_id: @sbtn.transaction_fee_id,
              tax_percent: @hash[:tax_percent],
              # At the moment, charge will only contain 1 line item, what if there are a couple line items?
              txn_uri: charge.id, currency: charge.currency,
              status: charge.status, last4: charge.source.last4,
              exp_month: charge.source.exp_month, exp_year: charge.source.exp_year,
              card_type: charge.source.brand, card_name: charge.source.name,
              subscription_id: @sbtn.id, destination: charge.destination, captured: charge.captured
            )

            @data.update(transaction_id: @txn.id, subscription_id: @sbtn.id)
            send_invoice_payment_succeeded_email
            @sbtn.transactions.count == 1 ? send_new_merchant_customer_subscription_email : send_merchant_subscription_notification_email
          end
        end
      end
    end
  end

  def send_new_merchant_customer_subscription_email
    date = DateTime.strptime(@sbtn.start.to_s, '%s').in_time_zone(@team.time_zone)
    options = {
      merchant: @team,
      customer: @customer,
      transaction_id: @txn.txn_number,
      plan_name: @sbtn.plan_name,
      frequency: @sbtn.plan_interval_name,
      transaction_date: @txn.created_at.strftime('%B %d, %Y | %-I:%M%P'),
      payment_method: "Visa **** **** **** #{@customer.last4} (Expiry #{@customer.exp_month}/#{@customer.exp_year})",
      description: @sbtn.description,
      currency: @sbtn.plan_currency,
      less_transaction_fees: @txn.txn_amount_less_fees,
      amount: @txn.txn_amount,
      currency_symbol: '$'
    }
    EmailingService.new_merchant_customer_subscription(options)
  end

  def send_merchant_subscription_notification_email
    date = DateTime.strptime(@sbtn.start.to_s, '%s').in_time_zone(@team.time_zone)
    options = {
      merchant: @team,
      customer: @customer,
      transaction_id: @txn.txn_number,
      plan_name: @sbtn.plan_name,
      frequency: @sbtn.plan_interval_name,
      date: @txn.created_at.strftime('%B %d, %Y | %-I:%M%P'),
      payment_method: "Visa **** **** **** #{@customer.last4} (Expiry #{@customer.exp_month}/#{@customer.exp_year})",
      description: @sbtn.description,
      currency: @sbtn.plan_currency,
      amount_less_fees: @txn.txn_amount_less_fees,
      amount: @txn.txn_amount,
      currency_symbol: '$'
    }
    EmailingService.merchant_subscription_notification(options)
  end

  def send_invoice_payment_succeeded_email
    date = DateTime.strptime(@data.date.to_s, '%s').in_time_zone(@team.time_zone)
    options = {
      frequency: @sbtn.plan_interval_name.downcase,
      plan_name: @sbtn.plan_name,
      stripe_invoice_id: @data.stripe_invoice_id,
      date: date.strftime('%B %d, %Y | %-I:%M%P'),
      status: 'Paid',
      payment_method: "Visa **** **** **** #{@customer.last4} (Expiry #{@customer.exp_month}/#{@customer.exp_year})",
      sub_total: Toolbox::Decimal.to_int_or_2dp(@data.subtotal.to_f/100),
      total: Toolbox::Decimal.to_int_or_2dp(@data.total.to_f/100),
      tax_and_fees: Toolbox::Decimal.to_int_or_2dp(@data.tax.to_f/100 + @data.application_fee.to_f/100),
      currency: @data.currency,
      currency_symbol: '$',
      customer: @customer
    }
    EmailingService.customer_subscription_receipt(options)
  end

  def invoice_payment_failed
    # find invoice and update...invoice should already exist but if it doesn't, create a new one
    @data = Invoice.where(stripe_invoice_id: @hash[:id]).first_or_initialize
    setup_invoice_data
    # notify customer
    team = @data.team
    date = DateTime.strptime(@data.date.to_s, '%s').in_time_zone(team.time_zone)
    options = {
      customer: @data.customer,
      merchant_business_name: team.org_name,
      merchant_email: team.email,
      plan_name: @data.subscription.plan_name,
      currency: @data.currency,
      currency_symbol: '$',
      frequency: @data.subscription.plan_interval_name,
      failed_date: date.strftime('%B %d, %Y | %-I:%M%P'),
      amount: Toolbox::Decimal.to_int_or_2dp(@data.total.to_f/100)
    }
    EmailingService.subscription_failed(options)
  end

  def customer_source_updated
    @source = @hash[:data][:object]

    # find customer
    mc = MerchantCustomer.find_by(managed_stripe_customer_id: @source[:customer])
    mc = MerchantCustomer.find_by(platform_stripe_customer_id: @source[:customer]) unless mc

    if mc
      @customer = mc.customer
      update_customer_source
      # notify admin only
      EmailingService.customer_source_updated(@customer)
    end
  end

  def update_customer_source
    @customer.last4 = @source[:last4]
    @customer.card_id = @source[:id]
    @customer.exp_month = @source[:exp_month]
    @customer.exp_year = @source[:exp_year]
    @customer.card_type = @source[:brand] if @source[:brand].present?
    @customer.card_name = @source[:name] if @source[:name].present?
    @customer.save
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
      ExceptionNotifier.notify_exception(exception, data: { message: "In StripeEvent account_updated", env: Rails.env,
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

  def bank_account_details
    bank_account_params = @account.external_accounts.data.first
    bank_account = BankAccount.find_by_stripe_bank_account_id(bank_account_params[:id])
    bank_account_details = {}
    bank_account_details[:bank_accounts_attributes] = { country: bank_account_params[:country],
                                                        # take this out for now cos CA number is concatenated
                                                        #routing_number: bank_account_params[:routing_number],
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
