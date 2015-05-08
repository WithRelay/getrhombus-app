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