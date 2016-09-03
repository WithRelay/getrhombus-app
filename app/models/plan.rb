class Plan < ActiveRecord::Base

  has_many :subscriptions 



  def create_plan(hash)

    uid = hash[:team].uid
    self.currency = hash[:currency]
    self.statement_descriptor = (self.name + "-" + hash[:team].org_name)[0..21]
    self.save

    hash.delete(:team)

    hash[:interval] = self.interval
    hash[:interval_count] = self.interval_count
    hash[:amount] = self.amount
    hash[:id] = self.id
    hash[:name] = self.name
    hash[:name] = self.trial_period_days
    hash[:statement_descriptor] = self.statement_descriptor

    #re = PaymentService(hash, uid)

    # save data
    # send emails

    self.id
  end


end
