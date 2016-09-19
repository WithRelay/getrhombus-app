class List < ActiveRecord::Base
	belongs_to :user
	has_many :customer_lists
	validates :name, presence:true
end
