class Api::V1::TransactionsController < API::V1::BaseController

	def refund
    if params[:type] == "card"  # Because Stripe supports different types
      # temp option for admin refunds
      admin = (current_user.is_platform?) ? true : false
      re = Refund.refund_card_txn(params[:charge_id], current_user.id, current_user.uid, params[:reason], admin)
      render :json => { message: re[0] }, status: re[1] and return
    end
    render :json => { message: "Not Implemented" }, status: 501		
	end

  def charge_customer
    # check for tag, if it doesnt exist, create one
    # then call charge customer with array
  end


end