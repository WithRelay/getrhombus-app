class User < ActiveRecord::Base

  #Stripe.api_key: '<redacted_api_key>'      # for test
  Stripe.api_key: '<redacted_api_key>'       # for production

  # Include default devise modules. Others available are:
    # :token_authenticatable, :lockable, :timeoutable and :confirmable,
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:stripe_connect]

  #has_many :messages, dependent: :destroy
  has_many :transactions, dependent: :destroy
  before_save :the_titleizer, :check_phone_number_length
  before_create :set_merchant_business_phone                   # only create, cos they can change this in edit
  after_create :set_rhombus_number, :send_welcome_email  

  validates_presence_of :user_level, :message => "Please select what you want to do with Rhombus"
  #validates_presence_of :card_name, :on => :update
  
  # still need a validation errors for edit
  validates :phone_number, presence: true, 
            numericality: { only_integer: true }, 
            length: { minimum: 10 }, 
            :on => :create

  # saves merchant info from stripe
  def from_omniauth(auth)
    self.provider = auth.provider
    self.uid = auth.uid
    self.stripe_access_token = auth.credentials.token
    self.stripe_publishable_key = auth.info.stripe_publishable_key
    self.stripe_scope = auth.info.scope
    self.stripe_livemode = auth.info.livemode
    if self.save
      return true
    else
      return false
    end
  end

  # Create or update customer on Stripe
  def add_token_to_stripe_customer(params)
    if self.user_level == 0 and !params[:instrument_uri].blank?
      begin 
        if self.customer_uri.blank?                                     # Doesnt have a customer uri => first time
          response = Stripe::Customer.create(:email => "#{self.email}", :card => params[:instrument_uri])         
          self.customer_uri = response.id
          self.stripe_livemode = response.livemode
          self.save
        else
          response = Stripe::Customer.retrieve(self.customer_uri)  
          response.email = self.email
          response.card = params[:instrument_uri]
          response.save   
        end
      rescue Stripe::CardError => e
        # Since it's a decline, Stripe::CardError will be caught
        body = e.json_body
        err  = body[:error]

        #owner = User.find_by(email: '<redacted_email>')                   # for development
        owner = User.find_by(email: '<redacted_email>')                # for production

        @message = Message.new
        @message.nexmo_send_text_message(18, owner.rhombus_number, self.phone_number, 
              "We were unable to update your card info on Rhombus because: #{err[:message]}.")

        Notification.token_failure_notification(err, self.email).deliver
        return false
      rescue Stripe::StripeError => e
        body = e.json_body
        err  = body[:error]
        Notification.token_failure_notification(err, self.email).deliver
        return false
      rescue StandardError => e
        Notification.token_failure_notification(e, self.email).deliver
        return false
      else
         return true                # we gat this
      end      
    end
    return true                     # why is this here??
  end

  # needs optimization
  def todays_stuff
    rhombus_number = self.rhombus_number          
    all_payments = self.transactions
    todays_payments = all_payments.where("created_at >= ?", Time.zone.now.beginning_of_day)
    total_1, total_2 = 0, 0
    if self.user_level == 0      
      all_payments.each do |p|
        total_1 = total_1 + p.amount_with_taxes
      end
      todays_payments.each do |p|
        total_2 = total_2 + p.amount_with_taxes
      end
    elsif self.user_level == 1      
      rhombus_number = "#{rhombus_number[0]}" + " " + "(#{rhombus_number[1..3]})" + " " + "#{rhombus_number[4..6]}-#{rhombus_number[7..10]}"
      all_payments.each do |p|
        total_1 = total_1 + p.amount_less_fees
      end
      todays_payments.each do |p|
        total_2 = total_2 + p.amount_less_fees
      end      
    end
    return total_1, total_2, todays_payments.count, rhombus_number
  end

  private

  def check_phone_number_length
    # temp fix for users who leave US code out. would need to change this eventually
    if self.user_level == 0 and self.phone_number.length == 10
      self.phone_number = "1" + self.phone_number
    end
  end

  def set_rhombus_number
    if self.user_level == 1
      @rhombus_number = Message.new
      self.rhombus_number = @rhombus_number.nexmo_search_and_buy_number("US")
      self.save
    end
  end

  def set_merchant_business_phone
    # If a merchant is signing up, make business number the phone number
    # Would be useful when merchants can become regular users and vice versa
    if self.user_level == 1
      self.business_phone = self.phone_number
      self.phone_number = nil
    end 
  end

  def the_titleizer       #remove leading and trailing whitespaces
    self.first_name = self.first_name.strip.titleize unless self.first_name.blank?
    self.last_name = self.last_name.strip.titleize unless self.last_name.blank?
    self.card_name = self.card_name.strip.titleize unless self.card_name.blank?
    self.business_type = self.business_type.strip.titleize unless self.business_type.blank?
    self.city = self.city.strip.titleize unless self.city.blank?
    self.state_province = self.state_province.strip.upcase unless self.state_province.blank?
    self.country = self.country.strip.upcase unless self.country.blank?
  end

  def send_welcome_email
    if self.user_level == 1
      Notification.welcome_email(self.email, self.user_level, self.first_name).deliver
    elsif self.user_level == 0
      Notification.welcome_email(self.email, self.user_level).deliver
    end
  end

end