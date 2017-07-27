class Api::V1::ConversationsController < API::V1::BaseController
  before_action :set_conversation, except: [:index, :find]
  before_action :check_user

	def index
    $redis_merchant_status.set(current_user.id.to_s, 'online') 

    if params[:select_conversation].present?
      conv = JSON.parse(params[:select_conversation]) 
      if conv['uid'].present? && conv['uid_type'].present?
        if ((conv['uid_type'] == 'user' && MerchantCustomer.exists?(customer_id: conv['uid'], merchant_id: current_user.id)) || 
            (conv['uid_type'] != 'user' && MerchantContact.exists?(uid: conv['uid'], uid_type: conv['uid_type'], merchant_id: current_user.id))) 
          conv = Conversation.find_or_create_conversation(current_user.id, conv["uid_type"], conv["uid"])
        else 
          conv = nil
        end
      else
        conv = nil
      end
    end

    re = { conversations: Conversation.get_open_conversations(current_user.id, params[:page]), count: Conversation.get_open_conversations_count(current_user.id) }
    re[:select_conversation] = conv.conversation_hash if conv
    render json: re, status: 200
	end

  def show
    #sleep 5
    messages_ary = Conversation.get_conversation_messages(@conversation, params[:conv_ref_id])
    render json: { messages: messages_ary[0], unread_ids: messages_ary[1] }  
  end

  def find
    conv = Conversation.find_or_create_conversation(current_user.id, params[:uid_type], params[:uid])
    render json: conv.conversation_hash, status: 200
  end

  def close
    # set resolution if any, mark all messages read, set is_resolved flag.
    
    conv_ref = @conversation.conversation_resolutions.last
    # you can have conversations without messages and so won't have a resolution object
    if !conv_ref || conv_ref.update_attributes(conversation_resolution_params)
      @conversation.update_attributes(is_resolved: true)
      @conversation.conversation_refs.update_all(unread: false)
      render json: {}, status: 200
    else
      # email team here
      render json: {}, status: 500
    end
  end

  def mark_messages_as_read
    render json: {}, status: @conversation.mark_messages_as_read(params[:ids]) ? 200 : 500 
  end

  def messages
    re = Conversation.send_message(@conversation, current_user, params[:msg], params[:channel], 'merchant') if params[:msg].present?
    if re
      render json: re.first, status: 200
    else 
      render json: {}, status: 500
    end
  end

  def mms
    begin      
      raise StandardError if params[:avatar].blank?
      # twilio supports only gif, png and jpeg though it accepts other types
      img = Image.create(avatar: params[:avatar])
      re = Conversation.send_message(@conversation, current_user, params[:msg], params[:channel], 'merchant', [img])
      raise StandardError unless re
      render json: re.first, status: :created
    rescue StandardError => e
      render json: { error: "Unable to upload file" }, status: 500
    end
  end

  private

    def set_conversation
      @conversation = Conversation.find_by(id: params[:id]) or not_found
    end

    def conversation_resolution_params
      params.require(:conversation_resolution).permit(:notes, :resolution).tap do |param|
        param[:notes] = param[:notes].present? ? param[:notes] : nil 
      end
    end

    def check_user
      render(json: {}, status: 500) if !current_user || current_user.is_customer?
    end

    def not_found
      render json: { error: 'not found' }, status: 404
    end

end