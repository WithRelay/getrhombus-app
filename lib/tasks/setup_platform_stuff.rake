namespace :platform do
  # 1
  ### Task no longer usable because of multi-numbers
  desc 'Setup platform user'
  task setup_user: :environment do
    user = User.find 1
    user.attributes = { id: 1, email: Rails.application.secrets.team_email,
                        password: '', user_level: 1,
                        rn_type: 'local', rn_country: 'US',
                        account_balance: 1_000_000, org_name: 'Relay', org_type: 'Company',
                        org_category: 'Other', currency: 'USD',
                        custom_welcome: '', relay_uid: 'ewqr12wer' }
    user.save(validate: false)
  end

  # 2. Also create on stripe dashboard - DONE
  desc 'Setup platform saas plans'
  task setup_saas_plans: :environment do
    platform_acct_id = User.get_platform_acct_obj.id # Must be right team email
    livemode = Rails.env.production?
    Plan.create([
                  { id: 1, status: 1, amount: 5000, currency: 'usd', interval: 'month', interval_count: 1,
                    stripe_livemode: livemode, name: 'Lite', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
                  { id: 2, status: 1, amount: 15_000, currency: 'usd', interval: 'month', interval_count: 1,
                    stripe_livemode: livemode, name: 'Basic', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
                  { id: 3, status: 1, amount: 35_000, currency: 'usd', interval: 'month', interval_count: 1,
                    stripe_livemode: livemode, name: 'Business', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
                  { id: 4, status: 1, amount: 70_000, currency: 'usd', interval: 'month', interval_count: 1,
                    stripe_livemode: livemode, name: 'Enterprise', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id }
                ])
  end

  # 3
  desc 'Setup stripe and sms fees'
  task setup_stripe_and_sms_fees: :environment do
    TransactionFee.create(id: 1, provider: 'stripe', fee_type: 0) # platform
    TransactionFee.create(id: 2, provider: 'stripe', provider_percent: '2.9') # standalone
    TransactionFee.create(id: 3, provider: 'stripe', platform_percent: '0.1') # managed
    SmsFee.create(id: 1, provider: 'twilio')
  end

  # 4
  # we use this on Stripe's website or anywhere else necessary
  desc 'Stripe referrer info'
  task setup_stripe_referrer: :environment do
    include Transactionable
    uid = generate_uid
    ref = Referrer.create(
      referrer_email: '<redacted_email>',
      referrer_name: 'Stripe',
      referrer_uid: uid,
      link: UrlShortenerService.shorten_link("#{Rails.application.secrets.app['url']}?referrer_uid=#{uid}")
    )
  end

  # 5
  desc 'remove duplicate message id in messages'
  task remove_duplicate_message_id_in_messages: :environment do
    sql = "UPDATE messages
            JOIN (SELECT messages.message_id
                    FROM messages
                GROUP BY messages.message_id
                   HAVING COUNT(*) > 1) x ON x.message_id = messages.message_id
             SET messages.message_id = null ;"
    ActiveRecord::Base.connection.execute('SET SQL_SAFE_UPDATES=0;')
    ActiveRecord::Base.connection.execute(sql)
    ActiveRecord::Base.connection.execute('SET SQL_SAFE_UPDATES=1;')
  end
end
