class List < ActiveRecord::Base
	belongs_to :user
	has_many :user_lists
	validates :name, presence:true
end
