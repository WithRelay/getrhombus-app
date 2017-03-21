class MerchantContactsController < ApplicationController
  include DashboardNotification
  before_action :set_notifications

  def index
    uid_type = params[:uid_type] || 'phone_number'
    @merchant_contacts = current_user.merchant_contacts.where(uid_type: uid_type)
  end
end
