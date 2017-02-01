class Api::V1::TransactionsController < API::V1::BaseController

  def refund
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
      if data[:hashtag_id].present?
        @hashtag = current_user.hashtags.where(id: data[:hashtag_id])  
      else
        @hashtag = ''''
      end
      @amount = Toolbox::Decimal.to_cents(data[:amount])
    end

end