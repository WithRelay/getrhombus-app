class AccountReload < ActiveRecord::Base
  belongs_to :user
	enum origin: [ :system, :merchant ]

  def reload(amt, user)
    txn = Transaction.new
    user = User.find 127  # to be removed

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
        transaction_id: txn.id,
        transaction_date: txn.created_at.strftime('%B %d,%Y | %-I:%M%P'),
        status: txn.status.capitalize,
        payment_method: "Visa **** **** **** #{user.last4} (Expiry #{user.exp_month}/#{user.exp_year})",
        amount: amt,
        currency: txn.currency,
        currency_symbol: '$',
        previous_balance: previous_balance,
        current_balance: current_balance,
      }
      EmailingService.sms_credit_receipt(options)
    else
      if re.fourth
        # send email about card issue
        puts 'card issue email here'
      end
    end

    re
  end

end
