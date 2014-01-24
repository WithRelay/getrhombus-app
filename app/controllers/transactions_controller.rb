class TransactionsController < ApplicationController

	def index
		trans = Transaction.new
		@response = trans.balanced_issue_refund_to_customer
	end
end