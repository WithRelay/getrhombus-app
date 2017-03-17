class AccountBalanceAlertJob
	@queue = :low_account_balance_alert

	def self.perform
		User.where(user_level: 1).each do |user|
			if user.account_balance < 5
				recharge(user.auto_reload_amt) if user.auto_reload
				EmailingService.account_balance_alert(user)
			end
		end
	end

	private

	def recharge(amt)
		# recharge logic
	end

end
