class Api::V1::TransactionsController < API::V1::BaseController

  def index
    @transactions = Transaction.where(team_id: current_user.id, captured: true, subscription_id: nil, user_id: params[:customer_id])
                                .order(created_at: :desc).limit(10)
                                .select([:amount, :created_at, :txn_number, :notes])

    render json: @transactions.as_json(methods: :relative_time)
  end

  def refund
    render json: { message: 'all done' } and return
    if params[:type] == "card"  # Because Stripe supports different types
      re = Refund.refund_card_txn(current_user.id, params, current_user.is_platform?)
      render json: { message: re[0] }, status: re[1]
    else
      render json: { message: "Not Implemented" }, status: 501		
    end
  end

  def create
    setup_charge_data
    re = process_dashboard_txn(@amount, current_user, @customer, params[:notes], @hashtag, params[:capture])
    if re[0]
      render json: { message: "Charge created" }, status: 200
    else
      render json: { error: re[1] }, status: 500
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:amount, :notes, :capture, :customer_id, :hashtag_id, :item_name)
    end

    def setup_charge_data
      @customer = User.find_by(id: data[:uid])
      data[:amount] = data[:amount].round(2)
      if data[:hashtag_id].present?
        @hashtag = current_user.hashtags.where(id: data[:hashtag_id]).first
      else
        @hashtag = Hashtag.new(skip_tag_validation: true)
        @hashtag.save(name: params[:item_name], description: params[:notes], amount: data[:amount], user_id: current_user.id, tag_type: 1, enable_tweet: 0)
      end
      @amount = Toolbox::Decimal.to_cents(data[:amount])
    end

end
