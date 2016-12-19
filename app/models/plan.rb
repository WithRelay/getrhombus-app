class Plan < ActiveRecord::Base

  has_many :subscriptions 
  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"

  validates_presence_of :name, :interval, :interval_count, :amount
  validates :name, uniqueness: { case_sensitive: false, scope: :merchant_id }
  validates_numericality_of :amount, :interval_count, greater_than: 0, only_integer: true
  after_create :create_plan_segment

  def create_plan(hash)
    begin
      res = []
      team = hash[:team]
      is_platform = team.is_platform?
      # uid = '<redacted_stripe_account_id>' #use this for testing
      uid = team.get_team_uid # use this for real use
      
      descriptor = (self.name + "-" + team.org_name)[0..21]

      # a customer or a team/merchant can create a plan
      _user_id = (hash.has_key? :customer) ? hash[:customer].id : hash[:team].id

      # dont send team/merchant or customer data in hash
      [:team, :customer].each { |k| hash.delete(k) }

      # Update so validations run before calling Stripe
      self.update(merchant_id: _user_id, statement_descriptor: descriptor, currency: team.currency)

      hash[:interval] = self.interval
      hash[:interval_count] = self.interval_count
      # amount should pass in cent
      hash[:amount] = self.amount
      hash[:id] = self.id
      hash[:name] = self.name
      hash[:trial_period_days] = self.trial_period_days
      hash[:statement_descriptor] = self.statement_descriptor
      hash[:currency] = self.currency

      res = PaymentService.create_plan(hash, uid, is_platform)
      if res.first && self.update(stripe_livemode: res.second.livemode)
        true
      else
        # if StandardError happens in create_plan after Stripe was called or update fails above
        self.delete_plan(team)
        #notify team via email
        false
      end

    rescue StandardError => e
      # if StandardError happens here after Stripe was called, delete plan on Stripe
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
      res = PaymentService.update_plan(self.id, hash, team.get_team_uid, team.is_platform?)
      
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

  def delete_plan(team)
    begin
      PaymentService.delete_plan(self.id, team.get_team_uid, team.is_platform?).first
    rescue StandardError => e
      # notify team via email
      false
    end
  end

  private
  # Triggered after a plan is created to get the users who belong to that plan
  def create_plan_segment
    segment = DashboardMerchantQueries.get_plan_users(self.id)
    l = List.new(name:self.name, user_id:merchant_id, segment:segment)
    l.save
  end
end
