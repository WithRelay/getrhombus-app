class MerchantContactsController < ApplicationController
  include DashboardNotification
  include UserProfile
  before_action :set_notifications

  def index
    uid_type = params[:uid_type] || 'phone_number'
    @merchant_contacts = current_user.merchant_contacts.where(uid_type: uid_type)
    @new_customer = User.new
    render 'merchant_contact_empty' unless @merchant_contacts.present?
  end

  def segment_users
    @merchant_contact = current_user.user_segments.contact.find_by(id: params[:id]).get_users
    @new_customer = User.new
    render 'merchant_contact_empty' unless @merchant_contact.present?
  end

  def show
    merchant_contact = MerchantContact.find_by_id(params[:id])
    @contact = merchant_contact.contacts
    @user_snapshot = get_user_snapshot(@contact.id, "user", current_user.id, @contact)
    @conversation_refs = ConversationRef.get_last_customer_msg_from_all_merchant_convs(current_user.id, @contact.id)
    @recent_activity = recent_activity
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
