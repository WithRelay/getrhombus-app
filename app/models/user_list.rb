class UserList < ActiveRecord::Base
  include PrettyDate

  belongs_to :list
  belongs_to :customer_contact, polymorphic: true

  # used by user_list api
  def user_added
    time_in_relative_form(self.created_at, 'long_format')
  end
end
