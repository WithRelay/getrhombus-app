class MessagesController < ApplicationController

  #include ProcessMessage
  include ProcessMessageTwilio

	def index
		#@message = Message.new
		#@url = @message.send_and_save_message(1, <redacted_phone_number>, <redacted_phone_number>, "$$$$ yea")
		#@url = TextingService.buy_number("US")
	end

	def receive_delivery_report
		render :text => ""											# return 200 to nexmo
		save_delivery_receipts(request.query_string)
	end

  def receive_delivery_report_twilio
    render :text => ""                      # return 200 to nexmo
    save_delivery_receipts(params)      # save delivery receipts twilio
  end

	def receive_text_message
		#params[:to] = "<redacted_phone_number>"
		#params[:msisdn] = "<redacted_phone_number>" 			# "<redacted_phone_number>"
		render :text => ""							# return 200 to nexmo
		process_message(request, params)
	end

  def receive_text_message_twilio
    message_body = params["Body"]
      from_number = params["From"]

      render :text => ""              # return 200 to twilio
    process_message(params)
  end

  def receive_voice_twilio
    render xml: TextingService.receive_call.to_xml
  end

  def dashboard_mms
    begin
      # twilio supports only gif, png and jpeg though it accepts other types
      @image = Image.create(avatar: params[:file])
      @message = Message.new
      @message.image_id = @image.id
      # need code for MMS here instead of 5  *************
      @message.send_and_save_message("5","<redacted_phone_number>","<redacted_phone_number>", "", @image.avatar.url)      
      render json: { message: "uploaded file" }, status: :created
    rescue StandardError => e
      render json: { message: "Unable to upload file" }, status: 500
    end
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


