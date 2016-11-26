#---
# Database seed of users 
#---
# encoding: utf-8

# Seeds for users
# User.delete_all

Transaction.create!(
	created_at: '2016-11-10 00:20:51',
	updated_at: '2016-11-10 00:20:51',
	referenced_user_id: 4,
	user_id: 4,
	team_id: 7,
	description: "Baggles purchase",
	amount: 20
)
Transaction.create!(
	created_at: '2016-11-19 00:20:51',
	updated_at: '2016-11-19 00:20:51',
	referenced_user_id: 40,
	user_id: 40,
	team_id: 7,
	description: "Milk",
	amount: 25
)
Transaction.create!(
	created_at: '2016-11-10 00:20:51',
	updated_at: '2016-11-10 00:20:51',
	referenced_user_id: 40,
	user_id: 40,
	team_id: 7,
	description: "Ballons",
	amount: 21.40
)
Transaction.create!(
	created_at: '2016-11-20 00:20:51',
	updated_at: '2016-11-20 00:20:51',
	referenced_user_id: 36,
	user_id: 36,
	team_id: 7,
	description: "Fish and Chips",
	amount: 20.89
)
Transaction.create!(
	created_at: '2016-11-30 00:20:51',
	updated_at: '2016-11-30 00:20:51',
	referenced_user_id: 35,
	user_id: 35,
	team_id: 7,
	description: "Eggplants",
	amount: 15
)
Transaction.create!(
	created_at: '2016-11-01 00:20:51',
	updated_at: '2016-11-01 00:20:51',
	referenced_user_id: 39,
	user_id: 39,
	team_id: 7,
	description: "Suya and Banana",
	amount: 50
)
Transaction.create!(
	created_at: '2016-11-25 00:20:51',
	updated_at: '2016-11-25 00:20:51',
	referenced_user_id: 36,
	user_id: 36,
	team_id: 7,
	description: "Eba & Amala",
	amount: 25
)
Transaction.create!(
	created_at: '2016-11-24 00:20:51',
	updated_at: '2016-11-24 00:20:51',
	referenced_user_id: 33,
	user_id: 33,
	team_id: 7,
	description: "Baked beans",
	amount: 5.15
)
Transaction.create!(
	created_at: '2016-11-05 00:20:51',
	updated_at: '2016-11-05 00:20:51',
	referenced_user_id: 29,
	user_id: 29,
	team_id: 7,
	description: "Sweet potato",
	amount: 30
)
Transaction.create!(
	created_at: '2016-11-20 00:20:51',
	updated_at: '2016-11-20 00:20:51',
	referenced_user_id: 25,
	user_id: 25,
	team_id: 7,
	description: "Chicken and eggs",
	amount: 20
)
Transaction.create!(
	created_at: '2016-11-10 00:20:51',
	updated_at: '2016-11-10 00:20:51',
	referenced_user_id: 24,
	user_id: 24,
	team_id: 7,
	description: "Akara and Kose",
	amount: 15.89
)
Transaction.create!(
	created_at: '2016-11-25 00:20:51',
	updated_at: '2016-11-25 00:20:51',
	referenced_user_id: 30,
	user_id: 30,
	team_id: 7,
	description: "Watermelons",
	amount: 25
)
Transaction.create!(
	created_at: '2016-10-10 00:20:51',
	updated_at: '2016-10-10 00:20:51',
	referenced_user_id: 41,
	user_id: 41,
	team_id: 7,
	description: "Broomsticks",
	amount: 20
)
Transaction.create!(
	created_at: '2016-11-14 00:20:51',
	updated_at: '2016-11-14 00:20:51',
	referenced_user_id: 22,
	user_id: 22,
	team_id: 7,
	description: "Fish and chips",
	amount: 30
)
Transaction.create!(
	created_at: '2016-11-25 00:20:51',
	updated_at: '2016-11-25 00:20:51',
	referenced_user_id: 21,
	user_id: 21,
	team_id: 7,
	description: "Chicken and eggs",
	amount: 24
)
Transaction.create!(
	created_at: '2016-10-10 00:20:51',
	updated_at: '2016-10-10 00:20:51',
	referenced_user_id: 4,
	user_id: 4,
	team_id: 7,
	description: "Baggles purchase",
	amount: 20
)
Transaction.create!(
	created_at: '2016-11-10 00:20:51',
	updated_at: '2016-11-10 00:20:51',
	referenced_user_id: 12,
	user_id: 12,
	team_id: 7,
	description: "Space heater",
	amount: 30
)
Transaction.create!(
	created_at: '2016-11-10 00:20:51',
	updated_at: '2016-11-10 00:20:51',
	referenced_user_id: 4,
	user_id: 4,
	team_id: 7,
	description: "Baggles purchase",
	amount: 20
)
Transaction.create!(
	created_at: '2016-11-25 00:20:51',
	updated_at: '2016-11-25 00:20:51',
	referenced_user_id: 6,
	user_id: 6,
	team_id: 7,
	description: "Oistein fish fry",
	amount: 30
)
Transaction.create!(
	created_at: '2016-11-20 00:20:51',
	updated_at: '2016-11-20 00:20:51',
	referenced_user_id: 33,
	user_id: 33,
	team_id: 7,
	description: "Breaded cake",
	amount: 25
)
Transaction.create!(
	created_at: '2016-11-23 00:20:51',
	updated_at: '2016-11-23 00:20:51',
	referenced_user_id: 33,
	user_id: 33,
	team_id: 7,
	description: "Sweet potato pie",
	amount: 28
)

# User.new(
# 	email: '<redacted_email>',
# 	first_name: 'Prince',
# 	last_name: 'Charles',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeff',
# 	last_name: 'Atkins',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Kemi',
# 	last_name: 'Atinkubo',
# 	password: 'password3',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Funsho',
# 	last_name: 'Ozabaza',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Barack',
# 	last_name: 'Obama',
# 	password: 'obamaforUsa',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Prince',
# 	last_name: 'Charles',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jazmine',
# 	last_name: 'Garcia',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Queen',
# 	last_name: 'Elizabeth',
# 	password: 'nigeria100',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Mike',
# 	last_name: 'Eisenberg',
# 	password: 'passwordformikae',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Samantha',
# 	last_name: 'Ryan',
# 	password: 'vanity789',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Gree',
# 	last_name: 'Horn',
# 	password: 'passingby2000',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeffrey',
# 	last_name: 'Prince',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeffrey',
# 	last_name: 'Tommbleton',
# 	password: 'greenpassword',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Timothy',
# 	last_name: 'Van Trump',
# 	password: 'password1',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Jeffrey',
# 	last_name: 'Simba',
# 	password: 'lovingme1000',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)
# User.create!(
# 	email: '<redacted_email>',
# 	first_name: 'Femi',
# 	last_name: 'Tokunbo',
# 	password: 'password34',
# 	phone_number: '<redacted_phone_number>',
# 	user_level: 0,
# 	is_active: true)

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