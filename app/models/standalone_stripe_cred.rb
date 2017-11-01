class StandaloneStripeCred < ActiveRecord::Base

  belongs_to :user
  belongs_to :transaction_fee  
  before_create :set_transaction_fee_id

  # the default
  def set_transaction_fee_id
    self.transaction_fee_id = 2
  end

  # saves merchant info from stripe for standalone accounts
  def self.from_omniauth(auth, id)
    begin
       where(user_id: id).first_or_initialize.tap do |row|
          row.email = auth.info.email
          row.account_id = auth.uid
          row.secret = auth.credentials.token
          row.publishable_key = auth.info.stripe_publishable_key
          row.scope = auth.info.scope
          row.livemode = auth.info.livemode
          row.save
       end
      true
    rescue StandardError => e
      false
    end
  end

end


