class MessagesController < ApplicationController

  # help remove delivery report from nexmo...no longer needed
  # help change links in nexmo and twilio
  # help in dasboard_mms...need params from and params to from dashboard

	def index
	end

  def receive_delivery_report
    render :text => ""                      # return 200 to nexmo
    save_delivery_receipts(params)          # save delivery receipts twilio
  end

	def receive_text_message_nexmo
		#params[:to] = "<redacted_phone_number>"
		#params[:msisdn] = "<redacted_phone_number>" 			# "<redacted_phone_number>"
		render :text => ""							# return 200 to nexmo
		process_message(request, params)
	end

  def receive_text_message
    render :text => ""              # return 200 to twilio
    process_message(params)
  end

  def receive_voice_twilio
    render xml: TextingService.receive_call.to_xml
  end

  def dashboard_mms
    #sleep 3
    #render json: { res: 'done'}, status: 200
    #puts params.inspect
    begin
      raise StandardError if !current_user || current_user.user_level == 0
      
      image = Image.create(avatar: params[:avatar])
      message = Message.new
      # twilio supports only gif, png and jpeg though it accepts other types
      message.image_ids = image.id
      
      # optional message here
      message.send_and_save_message("<redacted_phone_number>","<redacted_phone_number>", "", image.avatar.url)      
      
      render json: { response: "File uploaded and sent" }, status: :created
    rescue StandardError => e
      render json: { error: "Unable to upload file" }, status: 500
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


