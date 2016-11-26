class MerchantContact < ActiveRecord::Base
  belongs_to :merchant, class_name: "User"
end