class Plan < ActiveRecord::Base

  has_many :subscriptions 
  belongs_to :user

  def create_plan(hash)
    begin

      # uid = '<redacted_stripe_account_id>' #use this for testing
      uid = hash[:team].uid #use this for real use
      hash[:currency] = hash[:team].currency
      is_platform = hash[:team].is_platform?
      self.statement_descriptor = (self.name + "-" + hash[:team].org_name)[0..21]
      self.save

      # dont send team data in hash
      hash.delete(:team)

      hash[:interval] = self.interval
      hash[:interval_count] = self.interval_count
      hash[:amount] = self.amount
      hash[:id] = self.id
      hash[:name] = self.name
      hash[:trial_period_days] = self.trial_period_days
      hash[:statement_descriptor] = self.statement_descriptor

      if res = PaymentService.create_plan(hash, uid, is_platform).first
        self.update_attribute(stripe_livemode: res.second.livemode)
      else
        # notify team via email
      end

      res.first
    rescue StandardError => e
      false
    end
  end

  def update_plan(params, current_user)
    hash = params.require(:plan).permit(:name)
    hash[:statement_descriptor] = ( hash[:name] + "-" + current_user.org_name)[0..21]
    [PaymentService.update_plan(self.id.to_s, hash, current_user.uid,current_user.is_platform?),hash]
  end

  def delete_plan(current_user)
    PaymentService.delete_plan(self.id.to_s, current_user.uid,current_user.is_platform?)
  end

end
