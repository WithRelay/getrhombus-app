# This file describes the model of segments 
class Segment < ActiveRecord::Base
	belongs_to :list
	validates :list_id, presence: true
	validates :query, presence:true
end