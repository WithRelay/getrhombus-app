class TransactionsController < ApplicationController
	before_action :set_transaction, only: [:show]	# , :edit, :update, :destroy]

	load_and_authorize_resource

	def show
	end

	private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end
end


# Never trust parameters from the scary internet, only allow the white list through.
	#def transaction_params
    # params.require(:transaction).permit(:amount, :tax_rate)
    #end

=begin
	def index
		@transactions = current_user.transactions.where("id > ?", params[:after].to_i)
		if @transactions != nil
			total = 0
			@transactions.each do |t|
				total = total + t.amount_with_taxes
			end
			@new_total = total + params[:price][1..-1].to_f
		else
			@new_total = params[:price]
		end
		#trans = Transaction.new
		#@response = trans.balanced_credit_merchant_bank_account
	end
=end
