class Api::V1::TransactionsController < Api::V1::BaseController

  def index
    # Exclude refunded transactions, Exclude subscriptions since these queries are not read only
    # query is for refundable transactions
    # you can't refund subscriptions easily.
    # and include only captured transactions 
    # account reload txns are included by default..right
    @transactions = Transaction.exclude_refunded_transactions().exclude_subscriptions().select([:amount_with_taxes, :created_at, :txn_number, :notes])
                                .only_captured_transactions()
                                .where(user_id: params[:customer_id], team_id: current_user.id)
                                .order(created_at: :desc).limit(10)
                                .select([:created_at, :txn_number, :notes])

    render json: @transactions.as_json(methods: [:relative_time, :txn_amount])
  end

  def refund
    begin
      if params[:type] == "card"    # Because Stripe supports different types
        re = Refund.new.refund_card_txn(current_user, params)
        render json: { response: re.second }, status: (re.first ? 200 : 500)
      else
        render json: { response: "Cannot Perform this action." }, status: 500
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In V1::TransactionsController refund" } )
      render json: { response: "Something went wrong on our end." }, status: 500
    end
  end

  def create
    begin
      if current_user.is_platform? || (current_user.is_merchant? && current_user.get_stripe_cred[:type] == 'managed')
        customer = User.find_by(id: params[:transaction][:customer_id])
        re = customer.has_valid_card?
        if re[:valid]
          txn = Transaction.new
          tag = Hashtag.find_by(id: params[:transaction][:hashtag_id])
          amount = Toolbox::Decimal.to_cents(params[:transaction][:amount])
          capture = ['1', 'true', true].include?(params[:transaction][:capture]) ? true : false
          re = txn.process_dashboard_txn(amount, current_user, customer, params[:transaction][:notes], tag, capture, 'Message', 'dashboard-txn')
          if re.first
            render json: { response: "Transaction processed", transaction: txn.as_json(only: [:created_at, :txn_number, :notes], methods: [:relative_time, :txn_amount]) }
          else
            render json: { response: re.second }, status: 500
          end
        else
          render json: { response: re[:text] }, status: 500
        end
      else
        render json: { response: "Your account doesn't support dashboard payments" }, status: 500
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In V1::TransactionsController create" } )
      render json: { response: "Something went wrong on our end." }, status: 500
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:amount, :notes, :capture, :customer_id, :hashtag_id)
    end

end
