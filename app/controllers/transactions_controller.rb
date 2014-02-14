class TransactionsController < ApplicationController
	before_action :set_transaction, only: [:show]#, :edit, :update, :destroy]

	def index
		#trans = Transaction.new
		#@response = trans.balanced_credit_merchant_bank_account
	end

	def show
	end

	private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    #def transaction_params
     # params.require(:transaction).permit(:amount, :tax_rate)
    #end
end
