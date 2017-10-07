class MerchantCustomersController < ApplicationController

  include DashboardNotification
  include UserProfile
  before_action :set_notifications, except: [:business]

  def index
    @list_type = 'customer'
    @new_customer = User.new
    @merchant_customers = current_user.merchant_customers
                             .paginate(page: params[:page], per_page: PAGINATION_PER_PAGE).order(created_at: :desc)
    @merchant_customers.present? ? render_requested_format(@merchant_customers) : render(:empty_customer)
  end

  def business
    @businesses = MerchantCustomer.where(customer_id: current_user.id)
                                .paginate(page: params[:page], per_page: PAGINATION_PER_PAGE).order(created_at: :desc)
  end

  def show
    @merchant_customer = MerchantCustomer.find_by(id: params[:id])
    @user_snapshot = get_user_snapshot(@merchant_customer.customer_id, "user", current_user.id)

    # Exclude refunded transactions, Exclude subscriptions since these queries are not read only
    # query is for refundable transactions You can't refund subscriptions easily.
    # and include only captured transactions. account reload txns are included by default..right
    @transactions = Transaction.exclude_refunded_transactions().where(team_id: current_user.id).only_captured_transactions()
                                .exclude_subscriptions()
                                .where(user_id: @merchant_customer.customer_id).order(created_at: :desc)
                                .paginate(:page => params[:page], :per_page => PAGINATION_PER_PAGE)
    @conversation_refs = ConversationRef.get_last_customer_msg_from_all_merchant_convs(current_user.id, @merchant_customer.customer_id, 'user')
    @recent_activity = recent_activity
    render_requested_format(@transactions)
  end

  private

    def recent_activity
      last_conv_ref = @conversation_refs.present? ? @conversation_refs.first : nil
      last_message_resolution = last_conv_ref.uid_conversation_resolution.resolution if last_conv_ref.present?
      {
        last_transaction: @transactions ? @transactions.first : nil,
        last_conv_ref: last_conv_ref,
        last_message_resolution: last_message_resolution.present? ? last_message_resolution : nil
      }.compact
    end

end
