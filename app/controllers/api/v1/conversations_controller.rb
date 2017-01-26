class Api::V1::ConversationsController < API::V1::BaseController

	def index
    render json: { conversations: Conversation.get_open_conversations(current_user.id, params[:page]), 
                      count: Conversation.get_open_conversations_count(current_user.id) }
	end

  def show
    render json:  
  end

  # Returns JSON object with the last x messages a user has sent to the given merchant
  def json_get_user_messages_by_merchant
    if params[:limit]
      limit = params[:limit]
    else
      limit = CONFIG[:dashboard]['messaging']['num_messages_per_user_default']
    end
    render :json => Hash['success' => true, 'messages' => Message.get_user_messages_by_merchant(params[:user_number], params[:id], limit).paginate(page: params[:page], per_page: 20)].to_json
  end


  # help in dasboard_mms...need params from and params to from dashboard
  # add optional text
  def dashboard_mms
    #sleep 3
    #render json: { res: 'done'}, status: 200
    #puts params.inspect
    begin
      raise StandardError if !current_user || current_user.user_level == 0
      
      image = Image.create(avatar: params[:avatar])
      
      message = Message.new
      message.image_ids = image.id                                 # twilio supports only gif, png and jpeg though it accepts other types
      message.send_and_save_message(current_user.rn_type, "<redacted_phone_number>","<redacted_phone_number>", "", [image.avatar.url])      # optional message here
      
      render json: { response: "File uploaded and sent" }, status: :created
    rescue StandardError => e
      render json: { error: "Unable to upload file" }, status: 500
    end
  end

  def receive_voice_twilio
    render xml: TextingService.receive_call.to_xml
  end



end