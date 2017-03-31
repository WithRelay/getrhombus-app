class MerchantCustomersController < ApplicationController

  include DashboardNotification
  include UserProfile
  before_action :set_notifications

  def index

  	@customers = current_user.merchant_customers
                              .paginate(page: params[:page], per_page: 10).order(created_at: :desc)
  	@new_customer = User.new
    @customers.present? ? render_requested_format(@customers) : render(:empty_customer)
  end

  def show
  	@customer = User.find_by_id(customer_id)
    @user_snapshot = get_user_snapshot(customer_id, "user", current_user.id, @customer)
  	@merchant_customer = MerchantCustomer.find_by(customer_id: customer_id, merchant_id: current_user.id)

    # Exclude refunded transactions, Exclude subscriptions since these queries are not read only
    # query is for refundable transactions You can't refund subscriptions easily.
    # and include only captured transactions. account reload txns are included by default..right
    @transactions = Transaction.exclude_refunded_transactions().where(team_id: current_user.id).only_captured_transactions()
                            .exclude_subscriptions()
                            .where(user_id: customer_id).order(created_at: :desc)

    @conversation_refs = ConversationRef.get_last_customer_msg_from_all_merchant_convs(current_user.id, customer_id)
    @recent_activity = recent_activity
    # @last_transaction = @transactions.first
    #
    # @conversation_refs = ConversationRef.get_last_customer_msg_from_all_merchant_convs(current_user.id, customer_id)
    # @last_conv_ref = @conversation_refs.present? ? @conversation_refs.first : nil
    #
    # # refactor this at some point
    # if @last_conv_ref.present?
    #   @last_message_resolution = @last_conv_ref.uid_conversation_resolution.resolution
    #   @last_message_resolution.present? ? @last_message_resolution : "-"
    # else
    #   "-"
    # end
  end

  private
  def recent_activity
    last_conv_ref = @conversation_refs.present? ? conversation_refs.first : nil
    last_message_resolution = last_conv_ref.uid_conversation_resolution.resolution if last_conv_ref.present?
    {
      last_transaction: @transactions? @transactions.first : nil ,
      last_conv_ref: last_conv_ref,
      last_message_resolution: last_message_resolution.present? ? @last_message_resolution : nil
    }.compact
  end

  def customer_id
    params[:customer_id]
  end
end
