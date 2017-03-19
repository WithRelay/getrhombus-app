class TransactionsController < ApplicationController

  include DashboardNotification

  before_action :set_notifications, except: [:download_csv]
  before_action :set_transaction, only: [:show]

  # why am I not authorizing user?
  #load_and_authorize_resource :except => [:download_csv]
  respond_to :html

  def index
    if current_user.is_merchant?
      if params[:captured] == "false"
        @transactions = Transaction.includes(:user).where(team_id: current_user.id).only_uncaptured_transactions()
                                 .where("created_at >= ?", Time.zone.at(7.days.ago).to_i)
                                 .exclude_subscriptions()
                                 .paginate(page: params[:page], per_page: 10).order(created_at: :desc)
      else
        # Exclude refunded transactions, Exclude subscriptions since these queries are not read only
        # query is for refundable transactions
        # you can't refund subscriptions easily.
        # and include only captured transactions 
        # account reload txns are included by default..right
        @transactions = Transaction.includes(:user).exclude_subscriptions().only_captured_transactions()
                                    .exclude_refunded_transactions().where(team_id: current_user.id)
                                    .paginate(page: params[:page], per_page: 10).order(created_at: :desc)
      end
    else
      @transactions = []
    end
    render 'empty_transaction' unless @transactions.present?
  end

  # generate user csv data
  def download_csv
    render :template => "static_pages/to_404.html" and return if !current_user
    t = Transaction.new
    response = t.get_transactions_csv(current_user.id, current_user.is_merchant?, params[:txn_start_date], params[:txn_end_date])
    if response
      respond_to do |format|
        format.csv { send_data response, filename: "relay_transactions_#{Time.current.strftime("%d-%b-%y")}.csv" }
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
