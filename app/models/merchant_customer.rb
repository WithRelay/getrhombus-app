class MerchantCustomer < ActiveRecord::Base

  # platform_stripe_customer_id is the shared id between the platform and merchant standalone account
  # managed_stripe_customer_id is for the merchant managed account

  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  enum is_platform: { platform: 0, managed: 1 }
  has_many :subscriptions, inverse_of: :merchant_customer  

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
          platform = merchant.is_platform? ? :platform : :managed
          mc = find_by(merchant_id: merchant.id, customer_id: customer.id, is_platform: platform)
          if !mc
            create!(merchant_id: merchant.id, customer_id: customer.id, is_platform: platform)
          else
            mc.touch
          end

          return true
        end
      end
    rescue StandardError => err
      #email team
    end

    false
  end

end