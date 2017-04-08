class MerchantContact < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  belongs_to :contacts, class_name: "User", foreign_key: 'uid'

  def self.add_or_update_merchant_contact(merchant_id, uid, uid_type)
    begin
      find_or_create_by(merchant_id: merchant_id, uid: uid, uid_type: uid_type)
    rescue StandardError => err
    end
  end
end
