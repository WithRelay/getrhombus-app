# This file describes the model of segments 
class Segment < ActiveRecord::Base
	validates :list_id, presence: true
	validates :query, presence:true
end