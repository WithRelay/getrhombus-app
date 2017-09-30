class AccountBalanceAlertJob
	@queue = Rails.env + "_low_account_balance_alert"

	def self.perform
		ActiveRecord::Base.clear_active_connections!
		User.where(id: 127).each do |u|
			if u.account_balance.to_f < 5.0
				u.auto_reload? ? AccountReload.new.reload(u.auto_reload_amt, u) : EmailingService.account_balance_alert(u)
			end
		end
	end

end
