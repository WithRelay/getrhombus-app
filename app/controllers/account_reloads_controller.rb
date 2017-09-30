class AccountReloadsController < ApplicationController

  def create
    amt = Toolbox::Decimal.to_cents(params['user']['recharge_amount'])
    re = AccountReload.new.reload(amt, current_user)
    if re.first
      flash[:notice] = "Account balance updated. Your total balance is $#{Toolbox::Decimal.to_int_or_2dp(current_user.account_balance)}"
    else
      flash[:notice] = re.second      
    end
    redirect_to user_sms_usage_path
  end


end