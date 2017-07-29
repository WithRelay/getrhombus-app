class MerchantContact < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  has_many :user_lists, as: :customer_contact
  scope :only_contact, -> { where(is_customer: false) }

  def self.add_or_update_merchant_contact(merchant_id, uid, uid_type)
    begin
      if merchant_id.present? && uid.present?
        # Always update the updated_at field so we know the last time the contact interacted with the merchant
        find_or_create_by(merchant_id: merchant_id, uid: uid, uid_type: uid_type).touch
      end
    rescue StandardError => err
    end
  end

  def page_specific_id_valid?(merchant = nil)
    merchant = User.find self.merchant_id unless merchant
    merchant_page_id = merchant.fb_pages.subscribed.last.try(:id)
    return false unless merchant_page_id
    merchant_page.id == FbPage.find_by(page_specific_id: self.uid).try(:fb_page_id)
  end

end
