class StripeCred < ActiveRecord::Base

  # for saving array in fields_needed column http://api.rubyonrails.org/classes/ActiveRecord/Base.html#M001799
  serialize :legal_entity_verification, Hash
  serialize :account_verification, Hash

  belongs_to :user
  belongs_to :transaction_fee
  before_create :set_transaction_fee_id

  # the default
  def set_transaction_fee_id
    self.transaction_fee_id = 1
  end
end


