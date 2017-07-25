class MerchantContact < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  has_many :user_lists, as: :customer_contact
  scope :only_contact, -> { where(is_customer: false) }
  scope :facebook_contacts, -> { where(uid_type: 'fb_page') }

  def self.add_or_update_merchant_contact(merchant_id, uid, uid_type)
    begin
      if merchant_id.present? && uid.present?
        # Always update the updated_at field so we know the last time the contact interacted with the merchant
        find_or_create_by(merchant_id: merchant_id, uid: uid, uid_type: uid_type).touch
      end
    rescue StandardError => err
    end
  end

  def page_specific_id_valid?
    merchant = User.find self.merchant_id
    current_page_token = merchant.fb_pages.subscribed.last.page_access_token
    response = FacebookMessengerService.get_user_info(current_page_token, self.uid)
    response.present? ? true : false
  end

end
