class TransactionsController < ApplicationController

	def index
		trans = Transaction.new
		@response = trans.balanced_credit_merchant_bank_account
	end
end