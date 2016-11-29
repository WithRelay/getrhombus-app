class Invoice < ActiveRecord::Base
    has_one :notification_log, as: :notifiable, dependent: :destroy
end
