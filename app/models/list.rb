class List < ActiveRecord::Base
  belongs_to :user
  has_many :user_lists
  validates :name, presence:true
  has_many :campaigns, through: :campaign_lists
  has_many :campaign_lists
  has_one :segment, dependent: :destroy
end
