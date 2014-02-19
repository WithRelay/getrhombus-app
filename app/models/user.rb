class User < ActiveRecord::Base 	

	Balanced.configure('cb51061889c511e2ac81026ba7cd33d0')   

  # Include default devise modules. Others available are:
    # :token_authenticatable, :lockable, :timeoutable and :omniauthable, :confirmable,
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  #has_many :messages, dependent: :destroy
  has_many :transactions, dependent: :destroy
  before_save :the_titleizer
  before_create :set_merchant_business_phone                          # only create, cos they can change this in edit
  after_create :set_rhombus_number, :send_welcome_email  

  # still need a validation for edit
  validates :phone_number, presence: true, :on => :create
  validates_presence_of :user_level, :message => "Please select what you want to do with Rhombus"

   # Create or update customer on Balanced
  def balanced_associate_token_with_customer(params)
    begin            
      if self.customer_uri.blank?                                     # Doesnt have a customer uri => first time    
        customer = Balanced::Customer.new.save                        # Here self.customer_uri is the token from Balanced        
      else                                                            # Not blank 
        # so Balanced always retokenizes same card/bank info
        # the hash in the api can be used to check if info has already been tokenized
        # can add that later...for now info is retokenized
        customer = Balanced::Customer.find(self.customer_uri)       
      end

      if self.user_level == 0                                         # if it is a regular user => only cards
        response = customer.add_card(params[:instrument_uri])
      elsif self.user_level == 1                                      # if it is a merchant => only bank account
        # only bank accounts have unnecessary retokenization
        # cos edit form is the same for all fields
        response = customer.add_bank_account(params[:instrument_uri])
      end

    rescue Balanced::Error => e
        # handle bad response and notify marketplace owner of error
        # return e.response[:body]["status"], e.response[:body]["category_code"], e.response[:body]["description"], e.response[:body]["status_code"]
        Notification.token_failure_notification(e.response[:body], self.email).deliver
        return
    else
       # else save customer uri only.
       self.customer_uri = response.uri
       self.save
    end   
  end

  # needs optimization
  def todays_stuff

    rhombus_number = self.rhombus_number    
      
    all_payments = self.transactions#.where('DATE(created_at) = ?', Date.today)
    total = 0
    if self.user_level == 0
      all_payments.each do |p|
        total = total + p.amount_with_taxes
      end
    elsif self.user_level == 1
      rhombus_number = "#{rhombus_number[0]}" + " " + "(#{rhombus_number[1..3]})" + " " + "#{rhombus_number[4..6]}-#{rhombus_number[7..10]}"
      all_payments.each do |p|
        total = total + p.amount
      end
    end
    all_payments_total = total

    todays_payments = all_payments.where('DATE(created_at) = ?', Date.today)
    total = 0
    if self.user_level == 0
      todays_payments.each do |p|
        total = total + p.amount_with_taxes
      end
    elsif self.user_level == 1
      todays_payments.each do |p|
        total = total + p.amount
      end
    end
    todays_payments_total = total

    todays_payments_count = todays_payments.count

    return all_payments_total, todays_payments_total, todays_payments_count, rhombus_number
  end

  private

  def set_rhombus_number
    if self.user_level == 1
      @rhombus_number = Message.new
      self.rhombus_number = @rhombus_number.nexmo_search_and_buy_number("US")
      self.save
    end
  end

  def set_merchant_business_phone
    # If a merchant is signing up, make the business number the phone number
    # Would be useful when merchants can become regular users and vice versa
    if self.user_level == 1
      self.business_phone = self.phone_number
      self.phone_number = nil
    end 
  end

  def the_titleizer       #remove leading and trailing whitespaces
    self.name = self.name.strip.titleize unless self.name.blank?
    self.card_name = self.card_name.strip.titleize unless self.card_name.blank?
    self.business_name = self.business_name.strip.titleize unless self.business_name.blank?
    self.business_type = self.business_type.strip.titleize unless self.business_type.blank?
    self.street_address = self.street_address.strip.titleize unless self.street_address.blank?
    self.city = self.city.strip.titleize unless self.city.blank?
    self.state_province = self.state_province.strip.titleize unless self.state_province.blank?
    self.country = self.country.strip.titleize unless self.country.blank?
    self.account_name = self.account_name.strip.titleize unless self.account_name.blank?
  end

  def send_welcome_email
    if self.user_level == 1
      Notification.welcome_email(self.email, self.user_level, self.name).deliver
    elsif self.user_level == 0
      Notification.welcome_email(self.email, self.user_level).deliver
    end
  end

end










=begin
     def balanced_get_merchant_token(params)
        begin
          bank_account = Balanced::BankAccount.new(:account_number => params[:account_number], :name => params[:account_name],
                :routing_number => params[:routing_number], :type => params[:account_type]).save
        rescue Exception => e
           # handle bad response and notify marketplace owner of error
            # return e.response[:body]["status"], e.response[:body]["category_code"], e.response[:body]["description"], e.response[:body]["status_code"]
            #Notification.token_failure_notification(e.response[:body], self.email).deliver
        else
          # else assign the account uri to the instrument uri
          self.instrument_uri = bank_account.uri
          params[:instrument_uri] = bank_account.uri
        end
    end

    def balanced_verify_bank_account            # Only on account_uri attached to customers
      # call above function and pass account uri from above
      #account_uri = "/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4/bank_accounts/BA4HQALDlDDJrjvU9boIzfsY"
      #bank_account = Balanced::BankAccount.find(account_uri)
      #verification = bank_account.verify
      #return verification.uri
      ###### Process response...verification uri
    end

    def balanced_confirm_bank_account#(amount_1, amount_2)
      ###### Get user and then verification uri
      #verification_uri = "/v1/bank_accounts/BA4HQALDlDDJrjvU9boIzfsY/verifications/BZ4ABnWct4YS7XI62bjeJH1o"
      #verification = Balanced::Verification.find(verification_uri)
      #verification.amount_1 = 1#amount_1
      #verification.amount_2 = 1#amount_2
      #response = verification.save
      #return response.state
      ###### Process response
    end

    # Leave this for later. Unnecessary since it is already set in Balanced Dashboard
    # Pass in admin uri here
    #def balanced_add_account_to_marketplace_owner
      #marketplace.owner_customer.add_bank_account(uri)
      ##### handle response and save uri
    #end
=end