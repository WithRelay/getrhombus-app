class TransactionsController < ApplicationController

  include DashboardNotification
  include AdditionalUserActions

  before_action :set_notifications, except: [:index, :capture, :download_csv]
  respond_to :html

  load_and_authorize_resource

  def index
    if current_user.is_merchant?
      set_notifications
      where_str = "team_id = #{current_user.id}"
    else
      process_captured_payment
      where_str = "user_id = #{current_user.id}"
    end

    if params[:captured] == "false"
      @transactions = Transaction.includes(:user, :hashtag).where(where_str).only_uncaptured_transactions()
                               .where("created_at >= ?", Time.zone.at(7.days.ago))
                               .exclude_subscriptions()
                               .paginate(page: params[:page], per_page: PAGINATION_PER_PAGE)
                               .order(created_at: :desc)
    else
      # Exclude refunded transactions, Exclude subscriptions since these queries are not read only
      # query is for refundable transactions. You can't refund subscriptions easily.
      # and include only captured transactions. Account reload txns are included by default.right
      @transactions = Transaction.includes(:user, :hashtag).where(where_str).only_captured_transactions()
                                  .exclude_refunded_transactions()
                                  .exclude_subscriptions()
                                  .paginate(page: params[:page], per_page: PAGINATION_PER_PAGE)
                                  .order(created_at: :desc)
    end

    @authorized_txns = params[:captured] == "false" ? true : false
    @transactions.present? ? render_requested_format(@transactions) : render(:empty_transaction)
  end

  def process_captured_payment
    begin
      message = session.delete(:msg_id)
      channel = session.delete(:channel)
      if message.present? && ["Message", "FbMessage"].include?(channel)
        message = channel.constantize.find_by(id: message)
        merchant = User.find_by(id: message.try(:user_id_to))
        if message && message.transaction_id.blank? && merchant
          MessageParser.new.process_message(merchant, current_user, current_user.id, 'user', message, channel)
        end
      end
    rescue Exception => e
      ExceptionNotifier.notify_exception(e, env: request.env, data: { message: "In TransactionsController process_captured_payment", env: Rails.env })
    end
  end

  def capture
    begin
      transaction = Transaction.includes(:team, :user).find(params[:id])
      re = transaction.capture_uncaptured_txn
      flash[ re.first ? :notice : :error ] = re.second
    rescue Exception => e
      ExceptionNotifier.notify_exception(e, env: request.env, data: { message: "In TransactionsController capture", env: Rails.env, transaction: transaction })
    end
    redirect_to user_transactions_path(captured: 'false')
  end

  # generate user csv data
  def download_csv
    begin
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
    rescue Exception => e
      ExceptionNotifier.notify_exception(e, env: request.env, data: { message: "In TransactionsController download_csv", env: Rails.env })
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:amount)
    end

end
