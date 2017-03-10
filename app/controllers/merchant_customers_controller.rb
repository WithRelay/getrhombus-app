class MerchantCustomersController < ApplicationController

  include DashboardNotification
  before_action :set_notifications

  def index

  	@customers = current_user.merchant_customers
                              .paginate(page: params[:page], per_page: 10).order(created_at: :desc)
  	@new_customer = User.new
    render 'empty_customer' unless @customers
    respond_to do |format|
      format.js { render partial: 'shared/index.js.erb', locals: { obj: @customers } }
       format.html
     end
  end

  def show
    @customer_id = params[:customer_id]
  	@customer = User.find_by_id(@customer_id)

  	@merchant_customer = MerchantCustomer.find_by(customer_id: @customer_id, merchant_id: current_user.id)
    @transactions = Transaction.where(user_id: @customer_id, team_id: current_user.id).order(created_at: :desc)

    @conversation_refs = ConversationRef.get_last_customer_msg_from_all_merchant_convs(@merchant_customer.merchant_id)

    @last_conv_ref = @conversation_refs.present? ? @conversation_refs.first : nil
    @last_message_resolution = @last_conv_ref.present? && @last_conv_ref.resolution.present? ? @last_conv_ref.resolution : "-"
  end
end
