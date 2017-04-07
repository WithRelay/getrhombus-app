class StripeCred < ActiveRecord::Base

  # for saving array in fields_needed column http://api.rubyonrails.org/classes/ActiveRecord/Base.html#M001799
  serialize :fields_needed

  belongs_to :user
  belongs_to :transaction_fee  

  def can_accept_payments?
    charges_enabled && disabled_reason.blank?
  end

end


