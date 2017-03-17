class AccountBalanceAlertJob
	@queue = :low_account_balance_alert

	def self.perform
		User.where(user_level: 1).each do |user|
			if user.account_balance < 5
				EmailingService.account_balance_alert(user)
			end
		end
	end

end
