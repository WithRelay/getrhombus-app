class TransactionsController < ApplicationController
	
	before_action :set_transaction, only: [:show, :edit, :update, :destroy]

	# why am I not authorizing user?
	#load_and_authorize_resource :except => [:download_csv]
  respond_to :html

  def index
    if current_user.is_merchant?
      @transactions = current_user.get_merchant_transactions.paginate(:page => params[:page], :per_page => 25)
    else
      @transactions = current_user.get_customer_transactions.paginate(:page => params[:page], :per_page => 25)      
    end   
    respond_with(@transactions)
    #render layout: 'xxx' # remove
  end

	def show
	end

  # generate user csv data
	def download_csv
		render :template => "static_pages/to_404.html" and return if !current_user
    t = Transaction.new
		response = t.get_transactions_csv(current_user.id, current_user.user_level, params[:txn_start_date], params[:txn_end_date])
		if response
		  respond_to do |format|
		    format.csv { send_data response, filename: "rhombus_transactions_#{Time.zone.today.strftime("%d-%b-%y")}.csv" }	
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
     params.require(:transaction).permit(:amount)
    end

end
