class List < ActiveRecord::Base
  belongs_to :user
  has_many :user_lists
  validates :name, presence:true
  has_many :campaigns, through: :campaign_lists
  has_many :campaign_lists

  def get_users
  	if !segment.nil?
  		return User.find_by_sql segment
  	else
  		user_records = Array.new
  		user_lists.each do |customer|
        	user_records.push({ email: customer.user.email })
        	user_records.push({ user_id: customer.user.id })
      end
  		return user_records
  	end
  end

end
