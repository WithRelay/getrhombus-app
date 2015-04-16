class MessagesController < ApplicationController

	include ProcessMessage

	def index
		#@message = Message.new
		#@url = @message.send_and_save_message(1, <redacted_phone_number>, <redacted_phone_number>, "$$$$ yea")
		#@url = TextingService.buy_number("US")
	end

	def receive_delivery_report
		render :text => ""											# return 200 to nexmo
		save_delivery_receipts(request.query_string)
	end

	def receive_text_message
		#params[:to] = "<redacted_phone_number>"
		#params[:msisdn] = "<redacted_phone_number>" 			# "<redacted_phone_number>"
		render :text => ""							# return 200 to nexmo
		process_message(request, params)
	end


	private
	
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_params
      params.require(:message).permit(:text)
    end
	
end


