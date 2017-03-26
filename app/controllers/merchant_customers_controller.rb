class MerchantCustomersController < ApplicationController

  include DashboardNotification
  include UserProfile
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
    customer_id = params[:customer_id]
  	@customer = User.find_by_id(customer_id)
    @user_snapshot = get_user_snapshot(customer_id, "user", current_user.id, @customer)
  	@merchant_customer = MerchantCustomer.find_by(customer_id: customer_id, merchant_id: current_user.id)

    # Exclude refunded transactions, Exclude subscriptions since these queries are not read only
    # query is for refundable transactions You can't refund subscriptions easily.
    # and include only captured transactions. account reload txns are included by default..right
    @transactions = Transaction.exclude_refunded_transactions().where(team_id: current_user.id).only_captured_transactions()
                            .exclude_subscriptions()
                            .where(user_id: customer_id).order(created_at: :desc)
    @last_transaction = @transactions.first

    @conversation_refs = ConversationRef.get_last_customer_msg_from_all_merchant_convs(current_user.id, customer_id)
    @last_conv_ref = @conversation_refs.present? ? @conversation_refs.first : nil

    # refactor this at some point
    if @last_conv_ref.present?
      @last_message_resolution = @last_conv_ref.uid_conversation_resolution.resolution
      @last_message_resolution.present? ? @last_message_resolution : "-"
    else
      "-"
    end
  end
end
    
