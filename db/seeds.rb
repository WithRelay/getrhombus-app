#---
# Database seed of users
#---
# encoding: utf-8



KnowledgeBaseCategory.create(id: 1, name: 'Getting Started & Setup', slug:'getting_started_setup', image:'014_118.png')
KnowledgeBaseCategory.create(id: 2, name: 'Features Explained', slug:'features_explained', image:'017_228.png')
KnowledgeBaseCategory.create(id: 3, name: 'Phone Number', slug:'phone_number', image:'017_015.png')
KnowledgeBaseCategory.create(id: 4, name: 'Payments &amp; Transactions', slug:'payments_and_transactions', image:'014_014.png')
KnowledgeBaseCategory.create(id: 5, name: 'Pricing', slug:'pricing', image:'014_124.png')
KnowledgeBaseCategory.create(id: 6, name: 'My Account', slug:'my_account', image:'011_001.png')
KnowledgeBaseCategory.create(id: 7, name: 'Use Cases', slug:'use_cases', image:'004_010.png')
KnowledgeBaseCategory.create(id: 8, name: 'API', slug:'api', image:'007_052.png')
KnowledgeBaseCategory.create(id: 9, name: 'Privacy &amp; Terms', slug:'privacy_and_term', image:'013_008.png')

KnowledgeBase.create(
              id: 1,
              title: 'Create a Relay account for your business',
              author: 'Edwin',
              author_url: string,
              url: string,
              raw_content: 'Thank you for choosing Relay! To signup as a business please follow this link. All Relay plans come with a 14-day trial, including SMS credits to help you get started quickly.
                            If you’re not ready to choose a subscription plan, you can also sign-up for a limited free account that includes two-way messaging and payments from 25 contacts and/or customers, via SMS or Facebook Messenger.
                            Why collect payment information for a free account?
                            The free account is absolutely free — this means no monthly subscription! However, you will need to purchase SMS credits to message your customers, or connect your Facebook Messenger account.
                            Still have questions? We’ll be happy to walk you through Relay features relevant to your business use case, and answer all your questions. Schedule a demo here. You can also text us here [relay_dashboard_number] 😃 ',
              knowledge_base_category_id: 1)

KnowledgeBase.create(
              id: 2,
              title: 'Create a Relay customer account',
              author: 'Edwin',
              author_url: '',
              url: '',
              raw_content: 'Thank you for choosing Relay! To signup as a business please follow this link. All Relay plans come with a 14-day trial, including SMS credits to help you get started quickly.
                            If you’re not ready to choose a subscription plan, you can also sign-up for a limited free account that includes two-way messaging and payments from 25 contacts and/or customers, via SMS or Facebook Messenger.
                            Why collect payment information for a free account?
                            The free account is absolutely free — this means no monthly subscription! However, you will need to purchase SMS credits to message your customers, or connect your Facebook Messenger account.
                            Still have questions? We’ll be happy to walk you through Relay features relevant to your business use case, and answer all your questions. Schedule a demo here. You can also text us here [relay_dashboard_number] 😃 ',
              knowledge_base_category_id: 1)



# Seeds for users
# User.delete_all

#Plan.delete_all
platform_acct_id = User.get_platform_acct_obj.id
# Plan.create([
# 	{ id: 1, status: 1, amount: 0, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'A - 0 - 100', statement_descriptor: 'Relay', trial_period_days: 0, merchant_id: platform_acct_id },
# 	{ id: 2, status: 1, amount: 5000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'B - 101 - 1000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 3, status: 1, amount: 7500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'C - 1001 - 2500', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 4, status: 1, amount: 9000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'D - 2501 - 5000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 5, status: 1, amount: 10500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'E - 5001 - 7500', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 6, status: 1, amount: 12000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'F - 7501 - 10000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 7, status: 1, amount: 14500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'G - 10001 - 15000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 8, status: 1, amount: 19500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'H - 15001 - 20000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 9, status: 1, amount: 24000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'I - 20001 - 25000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 10, status: 1, amount: 29500, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'J - 250001 - 30000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 11, status: 1, amount: 35000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'K - 30001 - 35000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 12, status: 1, amount: 40000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'L - 350001 - 40000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 13, status: 1, amount: 45000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'M - 40001 - 45000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# 	{ id: 14, status: 1, amount: 50000, currency: 'usd', interval: 'month', interval_count: 1, stripe_livemode: 0, name: 'N - 45001 - 50000', statement_descriptor: 'Relay', trial_period_days: 14, merchant_id: platform_acct_id },
# ])




=begin
unless true
	# id = 1, platform
	 User.create!(
	 	email:"<redacted_email>",
	 	password: "samepassword",
	 	user_level:1,
	 	first_name:"Rhombus",
	 	last_name:"Relay",
	 	phone_number: '<redacted_phone_number>'
	 	# is_active: 1
	 )

#a standard merchant
#id = 2
 	User.create!(
 		email:"<redacted_email>",
 		password: "samepassword",
 		user_level:1,
 		first_name:"Mr.",
 		last_name:"Merchant",
 		phone_number: '<redacted_phone_number>'
 		# is_active: 1
 	)

#a standard customer
# id = 3
	User.create!(
		email:"<redacted_email>",
		password: "password",
		user_level:0,
		first_name:"Mr.",
		last_name:"Customer",
		phone_number: '<redacted_phone_number>'
		# is_active: 1
	)
end
#other merchant and non-merchant
#all even numbered ids are merchant and all odd(except 1) are customer
	10.times do
	 User.create!(
		 email: FFaker::Internet.email,
		 password: "samepassword",
		 user_level: 1,
		 first_name: FFaker::Name.first_name,
		 last_name: FFaker::Name.last_name,
		 phone_number: FFaker::PhoneNumber.short_phone_number.tr('-','').to_i
		#  is_active: 1
	 )

	 User.create!(
		 email: FFaker::Internet.email,
		 password: "samepassword",
		 user_level: 0,
		 first_name: FFaker::Name.first_name,
		 last_name: FFaker::Name.last_name,
		 phone_number: FFaker::PhoneNumber.short_phone_number.tr('-','').to_i
		#  is_active: 1
	 )

	end

	#50 saved_replies for Mr. Merchant
	50.times do
		SavedReply.create!(
			title: FFaker::Lorem.word + %w('' ' ' '_' '-' '--').sample + FFaker::Lorem.word,
			body: FFaker::Lorem.paragraph($nbSentences = 2),
			user_id: 2
		)


		name = FFaker::Name.name
		tag_type= [0,1,2].sample
		Hashtag.create!(
			description: FFaker::Lorem.paragraph($nbSentences = 2),
			amount: rand(500..15000),
			response: FFaker::Lorem.paragraph,
			name: name,
			tag: name.delete(' ') + rand(100).to_s,
			charge_amount: [0,1].sample,
			user_id: 2,
			interval_count: tag_type != 0 ? rand(2..5) : nil,
			interval: tag_type == 2 ? %w(weekly biweekly yearly).sample : nil,
			tag_type: tag_type,
			status: 1,
			enable_tweet: nil,
		)
	end

# Transaction.create!(
# 	created_at: '2016-11-10 00:20:51',
# 	updated_at: '2016-11-10 00:20:51',
# 	referenced_user_id: 4,
# 	user_id: 4,
# 	team_id: 7,
# 	description: "Baggles purchase",
# 	amount: 20
# )
# Transaction.create!(
# 	created_at: '2016-11-19 00:20:51',
# 	updated_at: '2016-11-19 00:20:51',
# 	referenced_user_id: 40,
# 	user_id: 40,
# 	description: "Milk",
# 	amount: 25
# 	team_id: 7,
# )
# Transaction.create!(
# 	created_at: '2016-11-10 00:20:51',
# 	updated_at: '2016-11-10 00:20:51',
# 	referenced_user_id: 40,
# 	user_id: 40,
# 	team_id: 7,
# 	description: "Ballons",
# 	amount: 21.40
# )
# Transaction.create!(
# 	created_at: '2016-11-20 00:20:51',
# 	updated_at: '2016-11-20 00:20:51',
# 	referenced_user_id: 36,
# 	user_id: 36,
# 	team_id: 7,
# 	description: "Fish and Chips",
# 	amount: 20.89
# )
# Transaction.create!(
# 	created_at: '2016-11-30 00:20:51',
# 	updated_at: '2016-11-30 00:20:51',
# 	referenced_user_id: 35,
# 	user_id: 35,
# 	team_id: 7,
# 	description: "Eggplants",
# 	amount: 15
# )
# Transaction.create!(
# 	created_at: '2016-11-01 00:20:51',
# 	updated_at: '2016-11-01 00:20:51',
# 	referenced_user_id: 39,
# 	user_id: 39,
# 	team_id: 7,
# 	description: "Suya and Banana",
# 	amount: 50
# )
# Transaction.create!(
# 	created_at: '2016-11-25 00:20:51',
# 	updated_at: '2016-11-25 00:20:51',
# 	referenced_user_id: 36,
# 	user_id: 36,
# 	team_id: 7,
# 	description: "Eba & Amala",
# 	amount: 25
# )
# Transaction.create!(
# 	created_at: '2016-11-24 00:20:51',
# 	updated_at: '2016-11-24 00:20:51',
# 	referenced_user_id: 33,
# 	user_id: 33,
# 	team_id: 7,
# 	description: "Baked beans",
# 	amount: 5.15
# )
# Transaction.create!(
# 	created_at: '2016-11-05 00:20:51',
# 	updated_at: '2016-11-05 00:20:51',
# 	referenced_user_id: 29,
# 	user_id: 29,
# 	team_id: 7,
# 	description: "Sweet potato",
# 	amount: 30
# )
# Transaction.create!(
# 	created_at: '2016-11-20 00:20:51',
# 	updated_at: '2016-11-20 00:20:51',
# 	referenced_user_id: 25,
# 	user_id: 25,
# 	team_id: 7,
# 	description: "Chicken and eggs",
# 	amount: 20
# )
# Transaction.create!(
# 	created_at: '2016-11-10 00:20:51',
# 	updated_at: '2016-11-10 00:20:51',
# 	referenced_user_id: 24,
# 	user_id: 24,
# 	team_id: 7,
# 	description: "Akara and Kose",
# 	amount: 15.89
# )
# Transaction.create!(
# 	created_at: '2016-11-25 00:20:51',
# 	updated_at: '2016-11-25 00:20:51',
# 	referenced_user_id: 30,
# 	user_id: 30,
# 	team_id: 7,
# 	description: "Watermelons",
# 	amount: 25
# )
# Transaction.create!(
# 	created_at: '2016-10-10 00:20:51',
# 	updated_at: '2016-10-10 00:20:51',
# 	referenced_user_id: 41,
# 	user_id: 41,
# 	team_id: 7,
# 	description: "Broomsticks",
# 	amount: 20
# )
# Transaction.create!(
# 	created_at: '2016-11-14 00:20:51',
# 	updated_at: '2016-11-14 00:20:51',
# 	referenced_user_id: 22,
# 	user_id: 22,
# 	team_id: 7,
# 	description: "Fish and chips",
# 	amount: 30
# )
# Transaction.create!(
# 	created_at: '2016-11-25 00:20:51',
# 	updated_at: '2016-11-25 00:20:51',
# 	referenced_user_id: 21,
# 	user_id: 21,
# 	team_id: 7,
# 	description: "Chicken and eggs",
# 	amount: 24
# )
# Transaction.create!(
# 	created_at: '2016-10-10 00:20:51',
# 	updated_at: '2016-10-10 00:20:51',
# 	referenced_user_id: 4,
# 	user_id: 4,
# 	team_id: 7,
# 	description: "Baggles purchase",
# 	amount: 20
# )
# Transaction.create!(
# 	created_at: '2016-11-10 00:20:51',
# 	updated_at: '2016-11-10 00:20:51',
# 	referenced_user_id: 12,
# 	user_id: 12,
# 	team_id: 7,
# 	description: "Space heater",
# 	amount: 30
# )
# Transaction.create!(
# 	created_at: '2016-11-10 00:20:51',
# 	updated_at: '2016-11-10 00:20:51',
# 	referenced_user_id: 4,
# 	user_id: 4,
# 	team_id: 7,
# 	description: "Baggles purchase",
# 	amount: 20
# )
# Transaction.create!(
# 	created_at: '2016-11-25 00:20:51',
# 	updated_at: '2016-11-25 00:20:51',
# 	referenced_user_id: 6,
# 	user_id: 6,
# 	team_id: 7,
# 	description: "Oistein fish fry",
# 	amount: 30
# )
# Transaction.create!(
# 	created_at: '2016-11-20 00:20:51',
# 	updated_at: '2016-11-20 00:20:51',
# 	referenced_user_id: 33,
# 	user_id: 33,
# 	team_id: 7,
# 	description: "Breaded cake",
# 	amount: 25
# )
# Transaction.create!(
# 	created_at: '2016-11-23 00:20:51',
# 	updated_at: '2016-11-23 00:20:51',
# 	referenced_user_id: 33,
# 	user_id: 33,
# 	team_id: 7,
# 	description: "Sweet potato pie",
# 	amount: 28
# )

# User.new(
# 	email: '<redacted_email>',
# 	first_name: 'Prince',
# 	last_name: 'Charles',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeff',
# 	last_name: 'Atkins',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Kemi',
# 	last_name: 'Atinkubo',
# 	password: 'password3',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Funsho',
# 	last_name: 'Ozabaza',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Barack',
# 	last_name: 'Obama',
# 	password: 'obamaforUsa',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Prince',
# 	last_name: 'Charles',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jazmine',
# 	last_name: 'Garcia',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Queen',
# 	last_name: 'Elizabeth',
# 	password: 'nigeria100',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Mike',
# 	last_name: 'Eisenberg',
# 	password: 'passwordformikae',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Samantha',
# 	last_name: 'Ryan',
# 	password: 'vanity789',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Gree',
# 	last_name: 'Horn',
# 	password: 'passingby2000',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeffrey',
# 	last_name: 'Prince',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeffrey',
# 	last_name: 'Tommbleton',
# 	password: 'greenpassword',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Timothy',
# 	last_name: 'Van Trump',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeffrey',
# 	last_name: 'Simba',
# 	password: 'lovingme1000',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Femi',
# 	last_name: 'Tokunbo',
# 	password: 'password34',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: 1)

#Seeds for Merchant users
#Clear the Merchant database
# MerchantCustomer.delete_all

# # Now insert new records
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 12,
# 	created_at: '2016-11-11 00:20:51',
# 	updated_at: '2016-11-11 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 4,
# 	created_at: '2016-11-08 00:20:51',
# 	updated_at: '2016-11-08 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 8,
# 	created_at: '2016-11-07 00:20:51',
# 	updated_at: '2016-11-07 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 25,
# 	created_at: '2016-11-11 11:20:51',
# 	updated_at: '2016-11-11 11:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 29,
# 	created_at: '2016-10-11 00:20:51',
# 	updated_at: '2016-10-11 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 6,
# 	created_at: '2016-09-10 00:20:51',
# 	updated_at: '2016-09-10 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 18,
# 	created_at: '2016-09-15 00:20:51',
# 	updated_at: '2016-09-15 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 12,
# 	created_at: '2016-10-15 00:20:51',
# 	updated_at: '2016-10-15 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 27,
# 	created_at: '2016-09-30 00:20:51',
# 	updated_at: '2016-09-30 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 21,
# 	created_at: '2016-10-01 00:20:51',
# 	updated_at: '2016-10-01 00:20:51'
# ).save!

# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 4,
# 	created_at: '2016-11-19 00:20:51',
# 	updated_at: '2016-11-19 00:20:51'
# ).save!
# MerchantCustomer.new(
# 	merchant_id: 7,
# 	customer_id: 25,
# 	created_at: '2016-11-15 00:20:51',
# 	updated_at: '2016-11-15 00:20:51'
# ).save!


# Remove all merchant contacts
# MerchantContact.delete_all

# # Create the merchant contacts relations

# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 30,
# 	created_at: '2016-11-01 10:20:51',
# 	updated_at: '2016-11-01 10:20:51'
# 	)

# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 31,
# 	created_at: '2016-11-14 10:20:51',
# 	updated_at: '2016-11-14 10:20:51'
# 	)
# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 32,
# 	created_at: '2016-11-19 10:20:51',
# 	updated_at: '2016-11-19 10:20:51'
# 	)
# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 33,
# 	created_at: '2016-11-22 10:20:51',
# 	updated_at: '2016-11-22 10:20:51'
# 	)

# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 34,
# 	created_at: '2016-11-10 00:20:51',
# 	updated_at: '2016-11-10 00:20:51'
# )

# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 35,
# 	created_at: '2016-11-07 10:20:51',
# 	updated_at: '2016-11-07 10:20:51'
# 	)

# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 44,
# 	created_at: '2016-11-15 10:20:51',
# 	updated_at: '2016-11-15 10:20:51'
# 	)

# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 43,
# 	created_at: '2016-11-18 10:20:51',
# 	updated_at: '2016-11-18 10:20:51'
# 	)
# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 41,
# 	created_at: '2016-11-13 10:20:51',
# 	updated_at: '2016-11-13 10:20:51'
# 	)
# MerchantContact.create!(
# 	merchant_id: 7,
# 	customer_id: 40,
# 	created_at: '2016-11-13 10:20:51',
# 	updated_at: '2016-11-13 10:20:51'
# 	)
=end
