class RefundsController < ApplicationController



	def create
		if params[:type] == "card"
			# temp option for admin refunds
			admin = (current_user.email == Rails.application.secrets.dashboard_email) ? true : false
	    	re = Refund.refund_card_txn(params[:charge_id], current_user.id, params[:reason], admin)
	      	render :json => { message: re[0] }, status: re[1] 
	      	return
	    end
    	render :json => { message: "Not Implemented" }, status: 501
	end


end