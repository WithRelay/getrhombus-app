class User < ActiveRecord::Base
 	
 	require 'balanced'
	Balanced.configure('cb51061889c511e2ac81026ba7cd33d0')   	

  	# Include default devise modules. Others available are:
  	# :token_authenticatable, 
  	# :lockable, :timeoutable and :omniauthable
  	devise :database_authenticatable, :registerable, :confirmable,
    	    :recoverable, :rememberable, :trackable, :validatable


    def balanced_associate_token_with_customer
   		
   		# Create or update customer on Balanced
   		######## if uri already exist => update card info
   		customer = Balanced::Customer.find('/v1/customers/CU7gMTGKh2yGHYn1lUxH9STS')
   		######## else add uri to db
   		customer = Balanced::Customer.new.save
   		######## end

   		######## Add response check and save info before proceeding

   		# Set uri token
   		token = "CC5iSapZxwZJ0H97eFKsuQVW"

   		######## if it is a credit card bank account
   		response = customer.add_card('/v1/marketplaces/TEST-MP6bP0y8O10lBsBfh8oMGhE4/cards/' + "#{token}")
   		######## elsif it is a bank account
   		response = customer.add_bank_account("/v1/bank_accounts/" + "#{token}")
   		###### end

		######## Process response here
   	end

   	def balanced_confirm_bank_account
   	end

   	def balanced_add_account_to_marketplace_owner
   		marketplace.owner_customer.add_bank_account(uri)
   		##### handle response and save uri
   	end





end
