class Plan < ActiveRecord::Base

  has_many :subscriptions 
  belongs_to :user

  validates_presence_of :name, :interval, :interval_count, :amount
  validates_numericality_of :interval_count, greater_than: 0, only_integer: true
  validates_numericality_of :amount, greater_than_or_equal_to: 1


  def create_plan(hash)
    begin
      res = []
      team = hash[:team]
      # uid = '<redacted_stripe_account_id>' #use this for testing
      uid = get_team_uid(team) #use this for real use
      is_platform = team.is_platform?
      
      descriptor = (self.name + "-" + team.org_name)[0..21]
      # a customer or a team/merchant can create a plan
      _user_id = (hash.has_key? :customer )? hash[:customer].id : hash[:team].id
      # dont send team/merchant or customer data in hash
      [:team, :customer].each { |k| hash.delete(k) } 
      # Update so validations run before calling Stripe
      self.update(user_id: _user_id, statement_descriptor: descriptor)

      hash[:interval] = self.interval
      hash[:interval_count] = self.interval_count
      hash[:amount] = self.amount
      hash[:id] = self.id
      hash[:name] = self.name
      hash[:trial_period_days] = self.trial_period_days
      hash[:statement_descriptor] = self.statement_descriptor
      hash[:currency] = team.currency

      res = PaymentService.create_plan(hash, uid, is_platform)
      if res.first
        self.update(stripe_livemode: res.second.livemode)
      else
        #notify team via email
      end

      res.first
    rescue StandardError => e
      # if StandardError happened after Stripe was called, delete plan on Stripe
      self.delete_plan(team) if res.length > 0
      # notify team via email
      false
    end
  end

  def update_plan(hash, team)
    begin

      old_name = self.name
      old_descriptor = self.statement_descriptor      
      new_descriptor = (hash[:name] + "-" + team.org_name)[0..21]
      
      # Update so validations run before calling Stripe api
      self.update(name: hash[:name], statement_descriptor: new_descriptor)
      hash[:statement_descriptor] = new_descriptor
      res = PaymentService.update_plan(self.id, hash, get_team_uid(team), team.is_platform?)
      
      unless res.first
        # notify team via email        
        # reverse data
        self.update(name: old_name, statement_descriptor: old_descriptor)
      end

      res.first
    rescue StandardError => e
      # notify team via email
      false
    end
  end

  def get_team_uid(team)
    t = team.stripe_creds.where(uid_type: 0).first
    t.uid if t
  end

  def delete_plan(team)
    begin
      PaymentService.delete_plan(self.id, get_team_uid(team), team.is_platform?).first
    rescue StandardError => e
      # notify team via email
      false
    end
  end

end
