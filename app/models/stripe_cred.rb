class StripeCred < ActiveRecord::Base

  belongs_to :user
  enum uid_type: [ :managed, :standalone ]
  
end