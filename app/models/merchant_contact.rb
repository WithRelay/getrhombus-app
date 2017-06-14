class MerchantContact < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  has_many :user_lists, as: :customer_contact

  scope :only_contact, -> { where(is_customer: false) }

  def self.add_or_update_merchant_contact(merchant_id, uid, uid_type)
    begin
      find_or_create_by(merchant_id: merchant_id, uid: uid, uid_type: uid_type) if merchant_id.present? && uid.present?
    rescue StandardError => err
    end
  end
end
