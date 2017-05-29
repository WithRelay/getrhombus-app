class StripeCred < ActiveRecord::Base

  # for saving array in fields_needed column http://api.rubyonrails.org/classes/ActiveRecord/Base.html#M001799
  serialize :fields_needed

  belongs_to :user
  belongs_to :transaction_fee
  before_create :set_transaction_fee_id

  has_one :image_ref, as: :imageable, dependent: :destroy
  has_one :image, through: :image_ref

  # the default
  def set_transaction_fee_id
    self.transaction_fee_id = 1
  end

  def can_accept_payments?
    charges_enabled && disabled_reason.blank?
  end

end


