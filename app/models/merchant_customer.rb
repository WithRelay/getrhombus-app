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

  def self.add_or_update_merchant_customer(merch, cus)
    begin
      return true if cus.is_platform? || merch.try(:id) == cus.try(:id)

      if merch.try(:id)
        # check for number and set is_customer
        if cus.try(:phone_number).present?
          merch.merchant_contacts.where(uid_type: 'phone_number', uid: cus.phone_number).update_all(is_customer: 1)
        end
        
        if cus.try(:id)
          # check for page_specific_ids and set is_customer
          creds = FbCred.where(user_id: cus.id).pluck(:page_specific_id)
          merch.merchant_contacts.where(uid_type: 'fb_page', uid: creds).update_all(is_customer: 1) if creds.present?

          # add as customer if necessary
          platform = merch.is_platform? ? 0 : 1
          mc = find_by(merchant_id: merch.id, customer_id: cus.id, is_platform: platform)
          if mc 
            mc.touch 
          else 
            mc = create!(merchant_id: merch.id, customer_id: cus.id, is_platform: platform)
          end

          return mc
        end
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, data: { message: "In add_or_update_merchant_customer", merchant: merch,
                                                            env: Rails.env, customer: cus })
    end

    false
  end

end