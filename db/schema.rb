# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160423033206) do

  create_table "full_contact_data", force: :cascade do |t|
    t.string   "likelihood",    limit: 191
    t.string   "photo_type_id", limit: 191
    t.string   "photo_url",     limit: 191
    t.string   "given_name",    limit: 191
    t.string   "family_name",   limit: 191
    t.string   "org_name",      limit: 191
    t.string   "org_title",     limit: 191
    t.string   "age_range",     limit: 191
    t.string   "gender",        limit: 191
    t.string   "city",          limit: 191
    t.string   "country",       limit: 191
    t.string   "website_url",   limit: 191
    t.string   "email",         limit: 191, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "full_contact_data", ["email"], name: "index_full_contact_data_on_email", unique: true, using: :btree

  create_table "full_contact_social_data", force: :cascade do |t|
    t.string   "bio",                  limit: 191
    t.string   "followers",            limit: 191
    t.string   "type_id",              limit: 191
    t.string   "url",                  limit: 191
    t.string   "following",            limit: 191
    t.integer  "full_contact_data_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "full_contact_social_data", ["full_contact_data_id"], name: "index_full_contact_social_data_on_full_contact_data_id", using: :btree

  create_table "hashtags", force: :cascade do |t|
    t.string   "name",            limit: 191
    t.decimal  "amount",                        precision: 8, scale: 2
    t.text     "response",        limit: 65535
    t.string   "tag",             limit: 191
    t.boolean  "is_precedent",    limit: 1,                             default: false
    t.integer  "user_id",         limit: 4
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
    t.boolean  "not_payment_tag", limit: 1
    t.boolean  "enable_tweet",    limit: 1
  end

  create_table "images", force: :cascade do |t|
    t.string   "avatar_file_name",    limit: 191
    t.string   "avatar_content_type", limit: 191
    t.integer  "avatar_file_size",    limit: 4
    t.datetime "avatar_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "from",              limit: 191
    t.string   "to",                limit: 191
    t.integer  "status_report_req", limit: 4
    t.string   "message_timestamp", limit: 191
    t.string   "message_price",     limit: 191
    t.string   "scts",              limit: 191
    t.string   "status",            limit: 191
    t.string   "status_delivery",   limit: 191
    t.string   "network_code",      limit: 191
    t.string   "error_text",        limit: 191
    t.string   "err_code",          limit: 191
    t.integer  "message_code",      limit: 4
    t.integer  "user_id_from",      limit: 4
    t.integer  "user_id_to",        limit: 4
    t.integer  "transaction_id",    limit: 4
    t.string   "messageId",         limit: 191
    t.text     "text",              limit: 65535
    t.boolean  "unread",            limit: 1,     default: true
    t.integer  "image_id",          limit: 4
  end

  add_index "messages", ["transaction_id"], name: "index_messages_on_transaction_id", using: :btree

  create_table "open_cnam_data", force: :cascade do |t|
    t.string   "name",         limit: 191
    t.string   "phone_number", limit: 191
    t.string   "price",        limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "open_cnam_data", ["phone_number"], name: "index_open_cnam_data_on_phone_number", unique: true, using: :btree

  create_table "refunds", force: :cascade do |t|
    t.string   "uri",        limit: 255
    t.string   "time",       limit: 255
    t.string   "reason",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transaction_uri",                    limit: 191
    t.integer  "transaction_type",                   limit: 4
    t.decimal  "amount",                                           precision: 8, scale: 2
    t.decimal  "amount_less_fees",                                 precision: 8, scale: 2
    t.string   "transaction_number",                 limit: 191
    t.string   "description",                        limit: 191
    t.string   "from",                               limit: 191
    t.string   "to",                                 limit: 191
    t.string   "status",                             limit: 191
    t.string   "transaction_available_at",           limit: 191
    t.string   "last_four",                          limit: 191
    t.string   "expiration_month",                   limit: 191
    t.string   "expiration_year",                    limit: 191
    t.string   "zip_code",                           limit: 191
    t.string   "card_type",                          limit: 191
    t.string   "card_name",                          limit: 191
    t.string   "tax_rate",                           limit: 191
    t.string   "on_behalf_of_uri",                   limit: 191
    t.string   "account_number",                     limit: 191
    t.string   "account_type",                       limit: 191
    t.string   "account_name",                       limit: 191
    t.string   "routing_number",                     limit: 191
    t.integer  "referenced_user_id",                 limit: 4
    t.string   "referenced_customer_transaction_id", limit: 191
    t.string   "receipt_sent_at",                    limit: 191
    t.integer  "user_id",                            limit: 4
    t.text     "notes",                              limit: 65535
    t.decimal  "amount_with_taxes",                                precision: 8, scale: 2
    t.integer  "referenced_merchant_transaction_id", limit: 4
    t.integer  "referenced_merchant_id",             limit: 4
    t.string   "currency",                           limit: 191
    t.integer  "refund_id",                          limit: 4
  end

  add_index "transactions", ["created_at"], name: "index_transactions_on_created_at", using: :btree
  add_index "transactions", ["referenced_customer_transaction_id"], name: "index_transactions_on_referenced_customer_transaction_id", using: :btree
  add_index "transactions", ["transaction_number"], name: "index_transactions_on_transaction_number", using: :btree
  add_index "transactions", ["user_id"], name: "index_transactions_on_user_id", using: :btree

  create_table "twilio_number_data", force: :cascade do |t|
    t.string   "city",         limit: 191
    t.string   "state",        limit: 191
    t.string   "zip",          limit: 191
    t.string   "country",      limit: 191
    t.string   "phone_number", limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "twilio_number_data", ["phone_number"], name: "index_twilio_number_data_on_phone_number", unique: true, using: :btree

  create_table "twitter_creds", force: :cascade do |t|
    t.string  "nickname",        limit: 191
    t.string  "name",            limit: 191
    t.string  "location",        limit: 191
    t.string  "image_url",       limit: 191
    t.string  "description",     limit: 191
    t.string  "website_url",     limit: 191
    t.string  "url",             limit: 191
    t.integer "followers_count", limit: 4,   default: 0
    t.integer "friends_count",   limit: 4,   default: 0
    t.string  "uid",             limit: 191
    t.string  "token",           limit: 191
    t.string  "secret",          limit: 191
    t.integer "user_id",         limit: 4
  end

  add_index "twitter_creds", ["user_id"], name: "index_twitter_creds_on_user_id", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                        limit: 191
    t.string   "encrypted_password",           limit: 191
    t.string   "reset_password_token",         limit: 191
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                limit: 4,     default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",           limit: 191
    t.string   "last_sign_in_ip",              limit: 191
    t.string   "confirmation_token",           limit: 191
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",            limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_level",                   limit: 4
    t.string   "customer_uri",                 limit: 191
    t.string   "last_four",                    limit: 191
    t.string   "expiration_month",             limit: 191
    t.string   "expiration_year",              limit: 191
    t.string   "zip_code",                     limit: 191
    t.string   "card_name",                    limit: 191
    t.string   "card_type",                    limit: 191
    t.string   "phone_number",                 limit: 191
    t.string   "business_name",                limit: 191
    t.string   "business_type",                limit: 191
    t.string   "street_address",               limit: 191
    t.string   "city",                         limit: 191
    t.string   "state_province",               limit: 191
    t.string   "business_phone",               limit: 191
    t.string   "country",                      limit: 191
    t.string   "rhombus_number",               limit: 191
    t.string   "routing_number",               limit: 191
    t.string   "account_name",                 limit: 191
    t.string   "account_number",               limit: 191
    t.string   "account_type",                 limit: 191
    t.boolean  "approve_payments_immediately", limit: 1,     default: false
    t.string   "tax_rate",                     limit: 191
    t.integer  "transactions_count",           limit: 4
    t.string   "instrument_uri",               limit: 191
    t.string   "business_zip_code",            limit: 191
    t.string   "provider",                     limit: 191
    t.string   "uid",                          limit: 191
    t.string   "stripe_access_token",          limit: 191
    t.string   "stripe_publishable_key",       limit: 191
    t.string   "stripe_scope",                 limit: 191
    t.string   "stripe_livemode",              limit: 191
    t.string   "stripe_refresh_token",         limit: 191
    t.string   "first_name",                   limit: 191
    t.string   "last_name",                    limit: 191
    t.boolean  "is_active",                    limit: 1,     default: true
    t.string   "referrer_num",                 limit: 191
    t.integer  "subscription_type",            limit: 4,     default: 0
    t.string   "url",                          limit: 191
    t.text     "custom_welcome",               limit: 65535
    t.string   "short_url",                    limit: 191
    t.string   "currency",                     limit: 191
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["phone_number"], name: "index_users_on_phone_number", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["rhombus_number"], name: "index_users_on_rhombus_number", unique: true, using: :btree

end
