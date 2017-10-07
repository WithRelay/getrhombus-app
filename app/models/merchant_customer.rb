class MerchantCustomer < ActiveRecord::Base

  # platform_stripe_customer_id is the shared id between the platform and merchant standalone account
  # managed_stripe_customer_id is for the merchant managed account
  
  enum is_platform: { platform: 0, managed: 1 }

  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  has_many :user_lists, as: :customer_contact
  
  has_many :subscriptions, inverse_of: :merchant_customer  

  delegate :email, to: :merchant, prefix: :merchant
  delegate :org_name, :rhombus_number, to: :merchant

  # has_many :invoices

  def self.add_or_update_merchant_customer(merchant, customer, platform_create = false)
    begin
      return true if merchant.is_platform? && platform_create

      if merchant.try(:id)
        # check for number and set is_customer
        if customer.try(:phone_number).present?
          merchant.merchant_contacts.where(uid_type: 'phone_number', uid: customer.phone_number).update_all(is_customer: 1)
        end
        
        if customer.try(:id)
          # check for page_specific_ids and set is_customer
          creds = FbCred.where(user_id: customer.id).pluck(:page_specific_id)
          merchant.merchant_contacts.where(uid_type: 'fb_page', uid: creds).update_all(is_customer: 1) if creds.present?

          # add as customer if necessary
          platform = merchant.is_platform? ? 0 : 1
          mc = find_by(merchant_id: merchant.id, customer_id: customer.id, is_platform: platform)
          mc ? mc.touch : create!(merchant_id: merchant.id, customer_id: customer.id, is_platform: platform)
          return mc
        end
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "In add_or_update_merchant_customer", 
                                                                            customer: customer })
    end

    false
  end

end