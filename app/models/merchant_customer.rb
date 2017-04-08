class MerchantCustomer < ActiveRecord::Base

  # platform_stripe_customer_id is the shared id between the platform and merchant standalone account
  # managed_stripe_customer_id is for the merchant managed account

  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  has_many :subscriptions, inverse_of: :merchant_customer
  # has_many :invoices

  def self.add_or_update_merchant_customer(merchant_id, customer)
    begin
      # check for number and set is_customer
      MerchantContact.where(uid_type: 'phone_number', uid: customer.phone_number).update_all(is_customer: true)

      # check for page_specific_ids and set is_customer
      creds = FbCred.where(user_id: customer.id).pluck(:page_specific_id)
      MerchantContact.where(uid_type: 'fb_page', uid: creds).update_all(is_customer: true) if creds.present?

      # add as customer
      find_or_create_by(merchant_id: merchant_id, customer_id: customer.id)
    rescue StandardError => err
    end
  end
end

