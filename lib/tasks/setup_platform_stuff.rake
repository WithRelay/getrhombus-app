namespace :platform do

  # 1
  desc "Setup platform user"
  task :setup_user => :environment do
    user = User.new(id: 1, email: '<redacted_email>', 
                    password: '<redacted_password>', user_level: 1, 
                    phone_number: '<redacted_phone_number>', rhombus_number: '<redacted_phone_number>', rn_type: 'local', rn_country: 'US',
                    account_balance: 1000000, org_name: 'Relay', org_type: 'Company',
                    org_category: 'Other', currency: 'USD', 
                    custom_welcome: '', relay_uid: 'ewqr12wer')
    user.save(validate: false)
  end

  # 2. Also create on stripe dashboard
  desc "Setup platform saas plans"
  task :setup_saas_plans => :environment do
    platform_acct_id = User.get_platform_acct_obj.id
    livemode = Rails.env.production?
    Plan.create([
      { id: 1, status: 1, amount: 0, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan A', statement_descriptor: 'Relay Platform', trial_period_days: 0, merchant_id: platform_acct_id },
      { id: 2, status: 1, amount: 5000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan B', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 3, status: 1, amount: 7500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan C', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 4, status: 1, amount: 9000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan D', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 5, status: 1, amount: 10500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan E', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 6, status: 1, amount: 12000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan F', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 7, status: 1, amount: 14500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan G', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 8, status: 1, amount: 19500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan H', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 9, status: 1, amount: 24000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan I', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 10, status: 1, amount: 29500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan J', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 11, status: 1, amount: 35000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan K', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 12, status: 1, amount: 40000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan L', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 13, status: 1, amount: 45000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan M', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
      { id: 14, status: 1, amount: 50000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: livemode, name: 'Plan N', statement_descriptor: 'Relay Platform', trial_period_days: 14, merchant_id: platform_acct_id },
    ])
  end

  # 3
  desc "Setup stripe and sms fees"
  task :setup_stripe_and_sms_fees => :environment do
    TransactionFee.create(id: 1, provider: 'stripe', fee_type: 0);
    TransactionFee.create(id: 2, provider: 'stripe');
    SmsFee.create(id: 1, provider: 'twilio');
  end

  #4
  # we use this on Stripe's website or anywhere else necessary
  desc "Stripe referrer info"
  task :setup_stripe_referrer => :environment do
    include Transactionable
    uid = generate_uid
    ref = Referrer.create(
      referrer_email: '<redacted_email>',
      referrer_name: 'Stripe',
      referrer_uid: uid,
      link: UrlShortenerService.shorten_link("#{Rails.application.secrets.app['url']}?referrer_uid=#{uid}")
    )
  end

end