class List < ActiveRecord::Base
  belongs_to :user
  has_many :user_lists
  validates :name, presence:true, uniqueness: { case_sensitive: false, scope: :user_id }
  has_many :campaigns, through: :campaign_lists
  has_many :campaign_lists

  # Gets the users that belong to a standard list or segment
  def get_users
  	if !segment.nil?
  		user_lists = User.find_by_sql([segment, {:id => user_id}])
  		return generate_list_users user_lists, type="segment"
  	else
  		return generate_list_users self.user_lists
  	end
  end

  private
    # Gets the users in the list or segment
    # @param user_lists An array or collection of users
    # based on the query or user lists
    # @param type The type of list. Default type is "list"
    # @return An array of hashes of user ids and email
    def generate_list_users user_lists, type="list"
      user_records = Array.new
      user_lists.each do |cus|
        if type == "list"
          customer = cus.user
        else
          customer = cus
        end
        user_records.push({ 
          email: customer['email'],
          user_id: customer['user_id']
          })
      end
      return user_records
    end
end
