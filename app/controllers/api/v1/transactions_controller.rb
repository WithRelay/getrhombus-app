class Api::V1::TransactionsController < API::V1::BaseController

	def refund
    if params[:type] == "card"  # Because Stripe supports different types
      re = Refund.refund_card_txn(current_user.id, params, current_user.is_platform?)
      render :json => { message: re[0] }, status: re[1]
    else
      render :json => { message: "Not Implemented" }, status: 501		
    end
	end

  def charge_customer
    # check for tag, if it doesnt exist, create one
    # then call charge customer with array
  end


end