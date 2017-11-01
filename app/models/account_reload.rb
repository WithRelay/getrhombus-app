class AccountReload < ActiveRecord::Base
  belongs_to :user
	enum origin: [ :system, :merchant ]

  def reload(amt, user)
    txn = Transaction.new

    re = txn.process_dashboard_txn(amt, User.get_platform_acct_obj, user, 'Account Reload')
    if re.first
      self.update(user_id: user.id, transaction_id: txn.id, origin: AccountReload.origins[:merchant])
      previous_balance = user.account_balance
      user.increment!(:account_balance, Toolbox::Decimal.cents_to_int_or_2dp(amt).to_f)
      current_balance = user.account_balance
      puts 'yay recharge is good'
      # send email here
      options = {
        merchant: user,
        transaction_id: txn.txn_number,
        transaction_date: txn.created_at.strftime('%B %d, %Y | %-I:%M%P'),
        status: txn.try(:status).try(:capitalize),
        payment_method: "Visa **** **** **** #{user.last4} (Expiry #{user.exp_month}/#{user.exp_year})",
        amount: Toolbox::Decimal.to_int_or_2dp(amt.to_f/100),
        currency: txn.currency,
        currency_symbol: '$',
        previous_balance: Toolbox::Decimal.to_int_or_2dp(previous_balance),
        current_balance: Toolbox::Decimal.to_int_or_2dp(current_balance),
      }
      EmailingService.sms_credit_receipt(options)
    else
      EmailingService.auto_reload_failure(user)
    end

    re
  end

end
