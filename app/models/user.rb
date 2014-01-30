class User < ActiveRecord::Base 	

	Balanced.configure('cb51061889c511e2ac81026ba7cd33d0')   

  has_many :transactions, dependent: :destroy
  #has_many :messages, dependent: :destroy	

 # before_create :set_merchant_business_phone

  	# Include default devise modules. Others available are:
  	# :token_authenticatable, :lockable, :timeoutable and :omniauthable, :confirmable,
  	devise :database_authenticatable, :registerable,
    	    :recoverable, :rememberable, :trackable, :validatable

    def balanced_associate_token_with_customer
   		# Pass in this uri from client
      #uri = "/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4/cards/CC1hYzxVE1aDLmo18kPpptks"
      uri = "/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4/cards/CC4MoQPn9NP4fe5lyjA1OV1"
      begin
       		# Create or update customer on Balanced
       		######## if current user has a uri, get uri, update card info and uri
          #customer_uri = "/v1/customers/CU16RllrJB2nxgdxhn23k68U "
       		#customer = Balanced::Customer.find(uri)
       		######## else create new customer on balanced and add uri to db
       		customer = Balanced::Customer.new.save
       		######## end
       		######## Add response check and save info before proceeding

     		  ######## if it is regular user => a credit card
     		    response = customer.add_card(uri)
     		  ######## elsif it is a merchant => bank account
     		    #response = customer.add_bank_account(uri)
          ###### end
      rescue Exception => e
          # Handle bad response and notify marketplace owner of error
          #return e.response[:body]["status"], e.response[:body]["category_code"], e.response[:body]["description"], e.response[:body]["status_code"]
          Notification.payment_failure_notification(e.response[:body]).deliver
      else
        # Else save customer uri only. Card/Account uri not needed cos 1:1
        return response.uri    
      end		
   	end

    private

    def set_merchant_business_phone
      # If a merchant is signing up
      if self.user_level == 1
        self.busines_phone = self.phone_number
      end
    end

end





















=begin
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