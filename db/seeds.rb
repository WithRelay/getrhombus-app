#---
# Database seed of users 
#---
# encoding: utf-8

# Seeds for users
# User.delete_all

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

# Seeds for Merchant users
# Clear the Merchant database
MerchantCustomer.delete_all

# Now insert new records
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 12,
	created_at: '2016-11-11 00:20:51',
	updated_at: '2016-11-11 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 4,
	created_at: '2016-11-08 00:20:51',
	updated_at: '2016-11-08 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 8,
	created_at: '2016-11-07 00:20:51',
	updated_at: '2016-11-07 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 25,
	created_at: '2016-11-11 11:20:51',
	updated_at: '2016-11-11 11:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 29,
	created_at: '2016-10-11 00:20:51',
	updated_at: '2016-10-11 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 6,
	created_at: '2016-09-10 00:20:51',
	updated_at: '2016-09-10 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 18,
	created_at: '2016-09-15 00:20:51',
	updated_at: '2016-09-15 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 12,
	created_at: '2016-10-15 00:20:51',
	updated_at: '2016-10-15 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 27,
	created_at: '2016-09-30 00:20:51',
	updated_at: '2016-09-30 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 21,
	created_at: '2016-10-01 00:20:51',
	updated_at: '2016-10-01 00:20:51'
).save!

MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 4,
	created_at: '2016-11-19 00:20:51',
	updated_at: '2016-11-19 00:20:51'
).save!
MerchantCustomer.new(
	merchant_id: 7,
	customer_id: 25,
	created_at: '2016-11-15 00:20:51',
	updated_at: '2016-11-15 00:20:51'
).save!
# Create transactions
