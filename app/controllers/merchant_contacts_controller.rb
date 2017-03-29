class MerchantContactsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications

  def index
    uid_type = params[:uid_type] || 'phone_number'
    @merchant_contacts = current_user.merchant_contacts.where(uid_type: uid_type)
    @new_customer = User.new
    render 'merchant_contact_empty' unless @merchant_contacts.present?
  end
end
