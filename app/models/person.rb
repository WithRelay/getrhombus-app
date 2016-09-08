class Person < ActiveRecord::Base

  has_one :address, as: :addressable
  belongs_to :user
end
