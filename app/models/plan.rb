class Plan < ActiveRecord::Base

  has_many :subscriptions
  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  belongs_to :hashtag, -> { where tag_type: 3 }

  validates_presence_of :name, :interval, :interval_count, :amount
  validates :name, uniqueness: { case_sensitive: false, scope: :merchant_id }
  validates_numericality_of :amount, :interval_count, greater_than_or_equal_to: 0, only_integer: true

  def create_plan(hash)
    begin
      res = []
      team = hash[:team]
      is_platform = team.is_platform?
      # uid = '<redacted_stripe_account_id>' #use this for testing
      uid = team.get_stripe_cred.uid # use this for real use

      descriptor = (self.name + "-" + team.org_name)[0..21]

      # dont send team/merchant in hash
      hash.delete(:team)
            
      # save so validations run before calling Stripe
      self.statement_descriptor = descriptor
      self.merchant_id = team.id
      self.currency = team.currency
      return false if !self.save

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
        create_plan_segment if self.customer_id.blank?
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

      # save so validations run before calling Stripe api
      self.name = hash[:name]
      self.statement_descriptor = new_descriptor
      return false if !self.save
      
      hash[:statement_descriptor] = new_descriptor
      res = PaymentService.update_plan(self.id, hash, team.get_stripe_cred.uid, team.is_platform?)

      if res.first
        update_plan_segment if self.customer_id.blank?
      else
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
      res = PaymentService.delete_plan(self.id, team.get_stripe_cred.uid, team.is_platform?).first
      delete_plan_segment if res
      res
    rescue StandardError => e
      # notify team via email
      false
    end
  end

  private
  # Creates a plan segment
  # This is called after a new plan is created.
  def create_plan_segment
    segment = DashboardMerchantQueries.get_plan_users(self.id)
    List.create(name:self.name, user_id: self.merchant_id, segment: segment, origin: 1)
  end

  def update_plan_segment
    old_name = self.previous_changes["name"]
    if old_name.present?
      l = List.find_by user_id: self.merchant_id, name: old_name[0]
      l.update(name: self.name) if l
    end
  end

  def delete_plan_segment
    l = List.find_by user_id: self.merchant_id, name: self.name
    l.destroy if l
  end
end
