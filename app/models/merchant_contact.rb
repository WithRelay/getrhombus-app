class MerchantContact < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
  belongs_to :contacts, class_name: "User", foreign_key: 'uid'
end
