class ApiCred < ActiveRecord::Base
  include Transactionable

  belongs_to :user
end
