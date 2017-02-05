class Api::V1::ConversationsController < API::V1::BaseController
  before_action :set_conversation, except: [:index]
  before_action :check_user
  before_action :set_recipient_object, only: [:messages, :mms, :show]

	def index
    if params[:select_conversation].present?
      conv = JSON.parse(params[:select_conversation]) 
      # Add check for if they are a user or contact, we dont want to create conversations for folks who dont exists
      conv = conv["uid"].present? ? Conversation.new.find_or_create_conversation(current_user.id, conv["uid_type"], conv["uid"]) : nil
    end

    re = { conversations: Conversation.get_open_conversations(current_user.id, params[:page]), 
            count: Conversation.get_open_conversations_count(current_user.id)  }
    re[:select_conversation] = conv.conversation_hash if conv
    render json: re, status: 200
	end

  def show
    messages_ary = @conversation.get_conversation_messages(params[:page], @customer)
    render json: { messages: messages_ary[0], unread_ids: messages_ary[1] }  
  end

  def mark_messages_as_read
    render json: {}, status: @conversation.mark_messages_as_read(params[:ids]) ? 200 : 500 
  end

  def messages
    # test that user is present here
    re = @conversation.send_message(current_user, params[:msg], params[:channel]) if params[:msg].present?
    if re
      render json: re, status: 200
    else 
      render json: {}, status: 500
    end
  end

  # help in dasboard_mms...need params from and params to from dashboard
  # add optional text
  def mms
    begin      
      raise StandardError if params[:avatar].blank?
      # twilio supports only gif, png and jpeg though it accepts other types
      img = Image.create(avatar: params[:avatar])
      re = @conversation.send_message(current_user, params[:msg], params[:channel], [img])
      raise StandardError unless re
      render json: re, status: :created
    rescue StandardError => e
      render json: { error: "Unable to upload file" }, status: 500
    end
  end

  private

    def set_conversation
      @conversation = Conversation.find_by(id: params[:id]) or not_found
    end

    def check_user
      render(json: {}, status: 500) if !current_user || current_user.is_customer?
    end

    def set_recipient_object
      @customer = User.find_by(@conversation.uid) if @conversation.uid_type == "user"
    end

    def not_found
      render json: { error: 'not found' }, status: 404
    end

end