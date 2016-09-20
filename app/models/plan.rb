class Plan < ActiveRecord::Base

  has_many :subscriptions 
  belongs_to :user

  def create_plan(hash)

    uid = hash[:team].uid
    hash[:currency] = hash[:team].currency
    self.statement_descriptor = (self.name + "-" + hash[:team].org_name)[0..21]
    self.save

    hash.delete(:team)

    hash[:interval] = self.interval
    hash[:interval_count] = self.interval_count
    hash[:amount] = self.amount
    hash[:id] = self.id
    hash[:name] = self.name
    hash[:trial_period_days] = self.trial_period_days
    hash[:statement_descriptor] = self.statement_descriptor

    #re = PaymentService(hash, uid)

    # save data
    # send emails

    self.id
  end


end
