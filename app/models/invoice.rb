class Invoice < ActiveRecord::Base
    belongs_to :subscription
    belongs_to :coupon
    # belongs_to :merchant_customer
    has_one :notification_log, as: :notifiable, dependent: :destroy
end
