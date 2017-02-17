class MerchantCustomersController < ApplicationController
  include DashboardNotification
  before_action :set_notifications

  def customers
  	@customers = current_user.customers
  	@new_customer = User.new
  end

  def show
  	@user = User.find_by_id(params[:id])
  	@merchant_customer = MerchantCustomer.find_by_customer_id(params[:id])

    @conversations = @user.merchant_conversations

  	@last_message_resolution = @user.message_resolutions.last 

  	@last_conversation = Conversation.find_last_conversation(@merchant_customer.merchant_id, 'user', @user.id)
  	@last_conversation_ref = ConversationRef.find_last_conversation_ref(@last_conversation) 

  	@transactions = Transaction.where(user_id: params[:id]).order(created_at: :desc)
  end
end
