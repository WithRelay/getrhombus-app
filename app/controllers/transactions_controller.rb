class TransactionsController < ApplicationController
	
	before_action :set_transaction, only: [:show]	# , :edit, :update, :destroy]

	# why am I not authorizing user?
	load_and_authorize_resource :except => [:spreadsheet]

	def show
	end

  # generate user spreadsheet data
	def spreadsheet
		render :template => "static_pages/to_404.html" and return if !current_user
		t = Transaction.new
		response = t.create_spreadsheet(current_user.id, current_user.level, params[:txn_start_date], params[:txn_end_date])
		if response
		  respond_to do |format|
		    format.xls { send_data response, :filename => "rhombus_transactions_#{params[:txn_todays_date]}.xls", :type =>  "", status: 200 }	
		  end
		else
		  # use 500 page after it is built
		  render :template => "static_pages/to_404.html"
		end
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