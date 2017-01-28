class Api::V1::ConversationsController < API::V1::BaseController
  before_action :set_conversation, except: [:index]

	def index
    render json: { conversations: Conversation.get_open_conversations(current_user.id, params[:page]), 
                    count: Conversation.get_open_conversations_count(current_user.id) }
	end

  def show
    messages_ary = @conversation.get_conversation_messages(params[:page])
    render json: { messages: messages_ary[0], unread_ids: messages_ary[1] }  
  end

  def mark_messages_as_read
    render json: {}, status: @conversation.mark_messages_as_read(params[:ids]) ? 200 : 500 
  end

  def send_merchant_message
    customer = User.find_by(params[:to]) if params[:uid_type] == "user"
    re = @conversation.send_message(current_user, customer, params[:to], params[:msg], params[:channel], params[:uid_type], false) if params[:msg].present?
    if re
      render json: re, status: 200
    else 
      render json: {}, status: 500
    end
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

  private

    def set_conversation
      @conversation = Conversation.find_by(id: params[:id], merchant_id: current_user.id) or not_found
    end

    def not_found
      render json: { error: 'not found' }, status: 404
    end

end