class AwayMessage < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :response, if: lambda { self.enabled? }
end
