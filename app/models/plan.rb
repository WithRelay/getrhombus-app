class Plan < ActiveRecord::Base

  enum owner: [ :platform, :team, :customer ]
  has_many :subscriptions 

end
