class AccountReload < ActiveRecord::Base
	enum origin: [ :system, :merchant ]

  def reload(amt, user)
    txn = Transaction.new    
    user = User.find 127  # to be removed

    re = txn.process_dashboard_txn(amt, User.get_platform_acct_obj, user, 'Account Reload')   
    if re.first
      self.update(user_id: user.id, transaction_id: txn.id, origin: AccountReload.origins[:merchant])
      user.increment!(:account_balance, Toolbox::Decimal.cents_to_int_or_2dp(amt).to_f)
      puts 'yay recharge is good'
      # send email here
    else 
      if re.fourth
        # send email about card issue
        puts 'card issue email here'
      end
    end
    
    re
  end

end
