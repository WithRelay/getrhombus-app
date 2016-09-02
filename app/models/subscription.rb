class Subscription < ActiveRecord::Base

  belongs_to :plans
  belongs_to :user
  belongs_to :coupons
  belongs_to :team, class_name: "User"

end
