class Coupon < ActiveRecord::Base

  has_many :subscriptions


  validates :name, uniqueness: { scope: :user_id }
end
