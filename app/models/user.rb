class User < ActiveRecord::Base
 	
 	require 'balanced'
  	
  	# Include default devise modules. Others available are:
  	# :token_authenticatable, 
  	# :lockable, :timeoutable and :omniauthable
  	devise :database_authenticatable, :registerable, :confirmable,
    	    :recoverable, :rememberable, :trackable, :validatable














end
