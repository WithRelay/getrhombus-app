class Plan < ActiveRecord::Base
  include SegmentQueries

  has_many :subscriptions
  belongs_to :merchant, class_name: "User"
  belongs_to :customer, class_name: "User"
  belongs_to :hashtag, -> { where tag_type: 3 }

  delegate :tag, to: :hashtag, prefix: :hashtag, allow_nil: true

  validates_presence_of :name, :interval, :interval_count, :amount
  validates :name, uniqueness: { case_sensitive: false, scope: :merchant_id }
  validates_numericality_of :amount, :interval_count, greater_than_or_equal_to: 0, only_integer: true
  validate :amount_greater_than_15000

  enum status: { inactive: 0, active: 1 }

  INTERVAL = { "week_1" => "Weekly", 'week_2' => "Bi-weekly", "month_1" => "Monthly", 
               'month_3' => "Every 3 months", 'month_6' => 'Every 6 months', 'year_1' => 'Yearly' }.freeze

  def create_plan(hash)
    begin
      res = []
      team = hash[:team]
      is_platform = team.is_platform?
      cred = team.get_stripe_cred

      if is_platform || (team.is_merchant? && cred[:type] == 'managed')
        descriptor = (self.name + "-" + team.org_name)[0..21]

        # dont send team/merchant in hash
        hash.delete(:team)

        # save so validations run before calling Stripe
        self.statement_descriptor = descriptor
        self.merchant_id = team.id
        self.currency = team.currency || 'usd'
        return false if !self.save

        hash[:interval] = self.interval
        hash[:interval_count] = self.interval_count
        # amount should pass in cent
        hash[:amount] = self.amount
        hash[:id] = self.id
        hash[:name] = self.name
        hash[:trial_period_days] = self.trial_period_days
        hash[:statement_descriptor] = self.statement_descriptor.gsub("'", "")
        hash[:currency] = self.currency

        res = PaymentService.create_plan(hash, cred[:cred], is_platform)
        if res.first && self.update(stripe_livemode: res.second.livemode)
          create_plan_segment if self.customer_id.blank?
          true
        else
          # if StandardError happens in create_plan after Stripe was called or update fails above
          self.delete_plan(team)
          #notify team via email
          false
        end
      else
        errors[:base] << "Your account doesn't support creating plans."
        false
      end
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "From create_plan in plan.rb"})
      # if StandardError happens here after Stripe was called, delete plan on Stripe
      self.delete_plan(team) if res.length > 0
      false
    end
  end

  def update_plan(hash, team)
    old_name = self.name
    old_descriptor = self.statement_descriptor
    begin
      new_descriptor = (hash[:name] + "-" + team.org_name)[0..21].gsub("'", "")

      # save so validations run before calling Stripe api
      self.name = hash[:name]
      self.statement_descriptor = new_descriptor
      return false unless self.save

      hash[:statement_descriptor] = new_descriptor
      res = PaymentService.update_plan(self.id, hash, team.get_stripe_cred[:cred], team.is_platform?)
      if res.first
        update_plan_segment if self.customer_id.blank?
      else
        # notify team via email
        # reverse data
        self.update(name: old_name, statement_descriptor: old_descriptor)
      end

      res.first
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "From update_plan in plan.rb"})
      self.update(name: old_name, statement_descriptor: old_descriptor)
      false
    end
  end

  def delete_plan(team)
    begin
      res = PaymentService.delete_plan(self.id, team.get_stripe_cred[:cred], team.is_platform?).first
      delete_plan_segment if res
      res
    rescue StandardError => exception
      ExceptionNotifier.notify_exception(exception, env: Rails.env, data: { message: "From delete_plan in plan.rb"})
      false
    end
  end

  def has_subscription?
    self.subscriptions.exists?
  end

  def interval_name
    INTERVAL["#{self.interval.downcase}_#{self.interval_count}"]
  end

  private
  # Creates a plan segment
  # This is called after a new plan is created.
  def create_plan_segment
    List.create(name:self.name, user_id: self.merchant_id, segment: plan_segment_data(self.id), 
                origin: List.origins[:system], list_type: List.list_types[:customer], campaign_type: List.campaign_types[:campaign])
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

  def amount_greater_than_15000
    errors.add(:amount, "can't be greater than 15000") if self.amount > 1500000
  end
end
