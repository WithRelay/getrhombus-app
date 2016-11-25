class StripeCred < ActiveRecord::Base

  # for saving array in fields_needed column http://api.rubyonrails.org/classes/ActiveRecord/Base.html#M001799
  serialize :fields_needed
  belongs_to :user
  enum uid_type: [ :managed, :standalone ]

  # valdation for stripecred attributes
  validates_presence_of :secret, :publishable_key, :user_agent, :tos_date, :ip

end
