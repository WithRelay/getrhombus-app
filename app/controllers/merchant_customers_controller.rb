class MerchantCustomersController < ApplicationController
  
  include DashboardNotification
  before_action :set_notifications

  def index
  	@customers = current_user.customers
  	@new_customer = User.new
  end

  def show
    
    @customer_id = params[:customer_id]
  	@user = User.find_by_id(@customer_id)
  	@merchant_customer = MerchantCustomer.find_by_customer_id(@customer_id)
    @transactions = Transaction.where(user_id: @customer_id).order(created_at: :desc)

    @conversations = @user.merchant_conversations
  	@last_message_resolution = @user.message_resolutions.last

  	@last_conversation = Conversation.find_last_conversation(@merchant_customer.merchant_id, 'user', @user.id)
  	@last_conversation_ref = ConversationRef.find_last_conversation_ref(@last_conversation)
  end
end
