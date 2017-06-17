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
end
