class Api::V1::TransactionsController < API::V1::BaseController

  def index
    # Exclude refunded transactions, Exclude subscriptions since these queries are not read only
    # query is for refundable transactions
    # you can't refund subscriptions easily.
    # and include only captured transactions 
    # account reload txns are included by default..right
    @transactions = Transaction.exclude_refunded_transactions().exclude_subscriptions()
                                .only_captured_transactions()
                                .where(user_id: params[:customer_id], team_id: current_user.id)
                                .order(created_at: :desc).limit(10)
                                .select([:amount, :created_at, :txn_number, :notes])

    render json: @transactions.as_json(methods: :relative_time)
  end

  def refund
    begin
      render(json: { response: 'all done' }, status: 500) and return
      if params[:type] == "card"  # Because Stripe supports different types
        re = Refund.refund_card_txn(current_user.id, params, current_user.is_platform?)
        render json: { response: re.second }, status: (re.first ? 200 : 500)
      else
        render json: { response: "Cannot Perform this action." }, status: 500	
      end
    rescue StandardError => e
      render json: { response: "Something went wrong on our end." }, status: 500
    end
  end

  def create
    begin
      render(json: { response: 'asdasdsa' }, status: 200) and return
      if setup_charge_data
        re = Transaction.new.process_dashboard_txn(@amount, current_user, @customer, params[:notes], @hashtag, params[:capture])
        if re.first
          render json: { response: "Charge created" }, status: 200
        else
          render json: { response: re.second }, status: 500
        end
      else
        render json: { response: "User doesn't have a valid card" }, status: 500
      end
    rescue StandardError => e
      render json: { response: "Something went wrong on our end." }, status: 500
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:amount, :notes, :capture, :customer_id, :hashtag_id, :item_name)
    end

    def setup_charge_data
      @customer = User.find_by(id: params[:user_id])
      return false unless @customer.has_valid_card?
      params[:amount] = params[:amount].round(2)
      @hashtag = current_user.hashtags.where(id: params[:hashtag_id]).first
      @amount = Toolbox::Decimal.to_cents(params[:amount])
      true
    end

end
