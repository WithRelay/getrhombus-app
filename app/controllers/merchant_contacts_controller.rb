class MerchantContactsController < ApplicationController
  include DashboardNotification
  include UserProfile
  before_action :set_notifications

  def index
    uid_type = params[:uid_type] == 'fb_page' ? 'fb_page' : 'phone_number'
    @channel = uid_type == 'phone_number' ? 'sms' : 'messenger'
    @list_type = 'contact'
    @new_customer = User.new
    @merchant_contacts = current_user.merchant_contacts.only_contact.where(uid_type: uid_type)
                                     .paginate(page: params[:page], per_page: PAGINATION_PER_PAGE).order(created_at: :desc)
    @merchant_contacts.present? ? render_requested_format(@merchant_contacts) : render(:merchant_contact_empty)
  end

  def show
    @merchant_contact = MerchantContact.find_by_id(params[:id])
    @user_snapshot = get_user_snapshot(@merchant_contact.uid, @merchant_contact.uid_type, current_user.id, @merchant_contact)
    @conversation_refs = ConversationRef.get_last_customer_msg_from_all_merchant_convs(current_user.id, @merchant_contact.uid, @merchant_contact.uid_type)
    @recent_activity = recent_activity
  end

  private

  def recent_activity
    last_conv_ref = @conversation_refs.present? ? @conversation_refs.first : nil
    last_message_resolution = last_conv_ref.uid_conversation_resolution.resolution if last_conv_ref.present?
    {
      last_transaction: nil,
      last_conv_ref: last_conv_ref,
      last_message_resolution: last_message_resolution.present? ? last_message_resolution : nil
    }.compact
  end
end
