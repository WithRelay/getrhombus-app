class MerchantCustomersController < ApplicationController
  
  include DashboardNotification
  before_action :set_notifications

  def index
  	@customers = current_user.merchant_customers
                              .paginate(page: params[:page], per_page: 10).order(created_at: :desc)
  	@new_customer = User.new
  end

  def show    
    @customer_id = params[:customer_id]
  	@user = User.find_by_id(@customer_id)

  	@merchant_customer = MerchantCustomer.find_by(customer_id: @customer_id, merchant_id: current_user.id)
    @transactions = Transaction.where(user_id: @customer_id, team_id: current_user.id).order(created_at: :desc)

  	@last_conv = Conversation.find_last_conversation(current_user.id, 'user', @user.id)
  	@last_conversation_ref = ConversationRef.find_last_conversation_ref(@last_conv)
    @last_message_resolution = @last_conv && @last_conv.resolution.present? ? @last_conv.resolution : ""

    @conversations = ConversationRef.get_last_customer_msg_from_all_merchant_convs(@merchant_customer.merchant_id)
  end
end
