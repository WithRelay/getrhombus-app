class MerchantContactsController < ApplicationController
  include DashboardNotification
  include UserProfile
  before_action :set_notifications

  def index
    @uid_type = params[:uid_type] == "fb_page" ? 'fb_page' : 'phone_number'
    @channel = @uid_type == 'phone_number' ? 'sms' : 'messenger'
    @merchant_contacts = current_user.merchant_contacts.where(uid_type: @uid_type)
    @new_customer = User.new
    render 'merchant_contact_empty' unless @merchant_contacts.present?
  end
  
  def show
    @merchant_contact = MerchantContact.find_by_id(params[:id])

    # this line is wrong... what is contacts? contacts dont have user objects
    # @contact = merchant_contact.contacts
    # incorrect parameters...see right params below, you are in contacts, there is no way you should be passing in 'user' here
    # please see methods for right parameters
    # @user_snapshot = get_user_snapshot(@contact.id, "user", current_user.id, @contact)
    # remove the commented lines after reading

    @user_snapshot = get_user_snapshot(@merchant_contact.uid, @merchant_contact.uid_type, current_user.id)
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
