class UserList < ActiveRecord::Base
  belongs_to :user
  belongs_to :list

 def get_all_users_on_list(list_id)
  	self.find_by(list_id: list_id)
 end

end
