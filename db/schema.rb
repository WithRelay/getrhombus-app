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

ActiveRecord::Schema.define(version: 20170102231149) do

  create_table "addresses", force: :cascade do |t|
    t.string   "street_address",   limit: 191
    t.string   "city",             limit: 191
    t.string   "state_province",   limit: 191
    t.string   "country",          limit: 191
    t.string   "postal_code",      limit: 191
    t.integer  "addressable_id",   limit: 4
    t.string   "addressable_type", limit: 191
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "addresses", ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable_type_and_addressable_id", using: :btree

  create_table "alerts", force: :cascade do |t|
    t.boolean  "send_alert",  limit: 1,   default: true
    t.integer  "interval",    limit: 4,   default: 15
    t.boolean  "include_sms", limit: 1,   default: false
    t.string   "sms_number",  limit: 191
    t.integer  "user_id",     limit: 4
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "alerts", ["user_id"], name: "fk_rails_a4db95c162", using: :btree

  create_table "bank_accounts", force: :cascade do |t|
    t.string   "stripe_bank_account_id", limit: 191
    t.string   "country",                limit: 191
    t.string   "bank_name",              limit: 191
    t.string   "account_number",         limit: 191
    t.string   "routing_number",         limit: 191
    t.string   "institution_number",     limit: 191, default: ""
    t.string   "currency",               limit: 191
    t.string   "status",                 limit: 191
    t.boolean  "default_for_currency",   limit: 1,   default: true
    t.boolean  "livemode",               limit: 1
    t.string   "fingerprint",            limit: 191
    t.integer  "user_id",                limit: 4
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
  end

  add_index "bank_accounts", ["fingerprint"], name: "index_bank_accounts_on_fingerprint", using: :btree
  add_index "bank_accounts", ["stripe_bank_account_id"], name: "index_bank_accounts_on_stripe_bank_account_id", using: :btree

  create_table "campaign_lists", force: :cascade do |t|
    t.integer  "campaign_id", limit: 4
    t.integer  "list_id",     limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "campaign_lists", ["campaign_id"], name: "fk_rails_98c7cf7ca4", using: :btree
  add_index "campaign_lists", ["list_id", "campaign_id"], name: "index_campaign_lists_on_list_id_and_campaign_id", using: :btree

  create_table "campaign_user_lists", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.integer  "campaign_id", limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "campaign_user_lists", ["campaign_id"], name: "fk_rails_a755147598", using: :btree
  add_index "campaign_user_lists", ["id", "user_id", "campaign_id"], name: "index_campaign_user_lists_on_id_and_user_id_and_campaign_id", using: :btree
  add_index "campaign_user_lists", ["user_id"], name: "fk_rails_29fac79585", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "name",           limit: 191
    t.integer  "channel",        limit: 4
    t.integer  "status",         limit: 4,          default: 1
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "user_id",        limit: 4
    t.boolean  "deliver_now",    limit: 1
    t.integer  "repeat_days",    limit: 4
    t.integer  "frequency_type", limit: 4
    t.datetime "date_time"
    t.text     "text",           limit: <redacted_phone_number>
    t.integer  "send_count",     limit: 4,          default: 0
    t.text     "subject",        limit: 65535
    t.integer  "campaign_type",  limit: 4,          default: 0
  end

  add_index "campaigns", ["id", "user_id"], name: "index_campaigns_on_id_and_user_id", using: :btree
  add_index "campaigns", ["user_id", "name"], name: "index_campaigns_on_user_id_and_name", unique: true, using: :btree

  create_table "conversation_refs", force: :cascade do |t|
    t.integer  "textable_id",     limit: 4
    t.string   "textable_type",   limit: 191
    t.integer  "conversation_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "conversation_refs", ["conversation_id"], name: "index_conversation_refs_on_conversation_id", using: :btree
  add_index "conversation_refs", ["textable_type", "textable_id"], name: "index_conversation_refs_on_textable_type_and_textable_id", using: :btree

  create_table "conversations", force: :cascade do |t|
    t.integer  "merchant_id",           limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes",                 limit: 65535
    t.string   "uid",                   limit: 191
    t.string   "uid_type",              limit: 191
    t.integer  "message_resolution_id", limit: 4
  end

  add_index "conversations", ["message_resolution_id"], name: "index_conversations_on_message_resolution_id", using: :btree

  create_table "coupons", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "stripe_coupon_id",   limit: 191
    t.string   "name",               limit: 191
    t.integer  "amount_off",         limit: 4
    t.string   "currency",           limit: 191
    t.string   "duration",           limit: 191
    t.integer  "duration_in_months", limit: 4
    t.integer  "max_redemptions",    limit: 4
    t.boolean  "stripe_livemode",    limit: 1
    t.integer  "percent_off",        limit: 4
    t.integer  "redeem_by",          limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "coupons", ["user_id", "name"], name: "index_coupons_on_user_id_and_name", unique: true, using: :btree
  add_index "coupons", ["user_id"], name: "index_coupons_on_user_id", using: :btree

  create_table "fb_creds", force: :cascade do |t|
    t.string   "email",            limit: 191
    t.string   "name",             limit: 191
    t.string   "fb_id",            limit: 191
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "auth_token",       limit: 191
    t.integer  "user_id",          limit: 4
    t.string   "time_zone",        limit: 191
    t.string   "gender",           limit: 191
    t.string   "page_specific_id", limit: 191
    t.text     "profile_pic_url",  limit: 65535
  end

  add_index "fb_creds", ["fb_id"], name: "index_fb_creds_on_fb_id", using: :btree
  add_index "fb_creds", ["id"], name: "index_fb_creds_on_id", unique: true, using: :btree
  add_index "fb_creds", ["user_id"], name: "index_fb_creds_on_user_id", using: :btree

  create_table "fb_messages", force: :cascade do |t|
    t.text     "text",           limit: 65535
    t.datetime "time_stamp"
    t.boolean  "unread",         limit: 1
    t.string   "message_id",     limit: 191
    t.integer  "transaction_id", limit: 4
    t.string   "from",           limit: 191
    t.string   "to",             limit: 191
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "campaign_id",    limit: 4
    t.integer  "seq",            limit: 4
    t.integer  "fb_page_id",     limit: 4
    t.integer  "user_id",        limit: 4
    t.integer  "user_id_to",     limit: 4
  end

  add_index "fb_messages", ["campaign_id"], name: "index_fb_messages_on_campaign_id", using: :btree
  add_index "fb_messages", ["fb_page_id"], name: "index_fb_messages_on_fb_page_id", using: :btree
  add_index "fb_messages", ["from"], name: "index_fb_messages_on_from", using: :btree
  add_index "fb_messages", ["to"], name: "index_fb_messages_on_to", using: :btree

  create_table "fb_pages", force: :cascade do |t|
    t.string   "page_id",             limit: 191
    t.integer  "user_id",             limit: 4
    t.string   "category",            limit: 191
    t.string   "page_access_token",   limit: 191
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "page_name",           limit: 191
    t.boolean  "subscription_status", limit: 1,   default: false
  end

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
    t.text     "description",    limit: 65535
    t.decimal  "amount",                       precision: 8, scale: 2
    t.text     "response",       limit: 65535
    t.string   "tag",            limit: 191
    t.boolean  "charge_amount",  limit: 1,                             default: false
    t.integer  "user_id",        limit: 4
    t.integer  "interval_count", limit: 4
    t.string   "interval",       limit: 191
    t.integer  "tag_type",       limit: 4
    t.boolean  "enable_tweet",   limit: 1
    t.datetime "created_at",                                                           null: false
    t.datetime "updated_at",                                                           null: false
  end

  add_index "hashtags", ["user_id"], name: "index_hashtags_on_user_id", using: :btree

  create_table "image_refs", force: :cascade do |t|
    t.integer  "imageable_id",   limit: 4
    t.string   "imageable_type", limit: 191
    t.integer  "image_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "image_refs", ["image_id"], name: "index_image_refs_on_image_id", using: :btree
  add_index "image_refs", ["imageable_type", "imageable_id"], name: "index_image_refs_on_imageable_type_and_imageable_id", using: :btree

  create_table "images", force: :cascade do |t|
    t.string   "avatar_file_name",    limit: 191
    t.string   "avatar_content_type", limit: 191
    t.integer  "avatar_file_size",    limit: 4
    t.datetime "avatar_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "uploaded_as",         limit: 4
  end

  create_table "invoices", force: :cascade do |t|
    t.integer "date",                 limit: 4
    t.string  "stripe_invoice_id",    limit: 191
    t.integer "coupon_id",            limit: 4
    t.integer "subscription_id",      limit: 4
    t.integer "transaction_id",       limit: 4
    t.integer "total",                limit: 4
    t.integer "subtotal",             limit: 4
    t.integer "tax",                  limit: 4
    t.string  "tax_percent",          limit: 191
    t.integer "application_fee",      limit: 4
    t.integer "amount_due",           limit: 4
    t.string  "currency",             limit: 191
    t.integer "starting_balance",     limit: 4
    t.integer "ending_balance",       limit: 4
    t.integer "period_start",         limit: 4
    t.integer "period_end",           limit: 4
    t.string  "statement_descriptor", limit: 191
    t.boolean "paid",                 limit: 1
    t.boolean "closed",               limit: 1
    t.boolean "attempted",            limit: 1
    t.integer "attempt_count",        limit: 4
    t.integer "next_payment_attempt", limit: 4
    t.boolean "forgiven",             limit: 1
    t.boolean "livemode",             limit: 1
    t.integer "merchant_customer_id", limit: 4
  end

  add_index "invoices", ["coupon_id"], name: "fk_rails_7aa1e153d5", using: :btree
  add_index "invoices", ["stripe_invoice_id"], name: "index_invoices_on_stripe_invoice_id", using: :btree
  add_index "invoices", ["subscription_id"], name: "fk_rails_46381ea356", using: :btree
  add_index "invoices", ["transaction_id"], name: "fk_rails_4ccc1b83a0", using: :btree

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 191
    t.text     "segment",    limit: 65535
    t.integer  "channel",    limit: 4,     default: 0
    t.integer  "origin",     limit: 4,     default: 0
  end

  add_index "lists", ["user_id", "name"], name: "index_lists_on_user_id_and_name", unique: true, using: :btree
  add_index "lists", ["user_id"], name: "index_lists_on_user_id", using: :btree

  create_table "merchant_contacts", force: :cascade do |t|
    t.integer  "merchant_id",      limit: 4
    t.string   "customer_id",      limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "customer_id_type", limit: 191
  end

  add_index "merchant_contacts", ["customer_id"], name: "index_merchant_contacts_on_customer_id", using: :btree
  add_index "merchant_contacts", ["merchant_id"], name: "index_merchant_contacts_on_merchant_id", using: :btree

  create_table "merchant_customers", force: :cascade do |t|
    t.integer  "merchant_id",        limit: 4
    t.integer  "customer_id",        limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "stripe_customer_id", limit: 191
  end

  add_index "merchant_customers", ["customer_id"], name: "index_merchant_customers_on_customer_id", using: :btree
  add_index "merchant_customers", ["merchant_id"], name: "index_merchant_customers_on_merchant_id", using: :btree

  create_table "message_resolutions", force: :cascade do |t|
    t.string   "title",      limit: 191
    t.integer  "user_id",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "message_resolutions", ["user_id"], name: "fk_rails_f8c7615aa7", using: :btree

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "from",                     limit: 191
    t.string   "to",                       limit: 191
    t.string   "message_timestamp",        limit: 191
    t.string   "message_price",            limit: 191
    t.string   "status",                   limit: 191
    t.string   "error_text",               limit: 191
    t.string   "error_code",               limit: 191
    t.integer  "user_id",                  limit: 4
    t.integer  "user_id_to",               limit: 4
    t.integer  "transaction_id",           limit: 4
    t.string   "message_id",               limit: 191
    t.text     "text",                     limit: 65535
    t.boolean  "unread",                   limit: 1,     default: true
    t.string   "num_segments",             limit: 191
    t.string   "price_unit",               limit: 191
    t.integer  "hashtag_id",               limit: 4
    t.boolean  "unread_notification_sent", limit: 1,     default: false
  end

  add_index "messages", ["hashtag_id"], name: "index_messages_on_hashtag_id", using: :btree
  add_index "messages", ["transaction_id"], name: "index_messages_on_transaction_id", using: :btree
  add_index "messages", ["user_id"], name: "index_messages_on_user_id", using: :btree

  create_table "next_plans", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "plan_id",    limit: 4
    t.boolean  "status",     limit: 1
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "next_plans", ["plan_id"], name: "index_next_plans_on_plan_id", using: :btree

  create_table "notification_logs", force: :cascade do |t|
    t.integer  "notifiable_id",   limit: 4
    t.string   "notifiable_type", limit: 191
    t.string   "notify_type",     limit: 191
    t.string   "channel",         limit: 191
    t.integer  "channel_id",      limit: 4
    t.string   "reason",          limit: 191
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "notification_logs", ["channel_id"], name: "index_notification_logs_on_channel_id", using: :btree
  add_index "notification_logs", ["notifiable_type", "notifiable_id"], name: "index_notification_logs_on_notifiable_type_and_notifiable_id", using: :btree

  create_table "open_cnam_data", force: :cascade do |t|
    t.string   "name",         limit: 191
    t.string   "phone_number", limit: 191
    t.string   "price",        limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "open_cnam_data", ["phone_number"], name: "index_open_cnam_data_on_phone_number", unique: true, using: :btree

  create_table "people", force: :cascade do |t|
    t.string   "first_name",    limit: 191
    t.string   "last_name",     limit: 191
    t.integer  "role",          limit: 4
    t.string   "dob",           limit: 191
    t.string   "last4",         limit: 191
    t.string   "stripe_pii_id", limit: 191
    t.boolean  "livemode",      limit: 1
    t.integer  "user_id",       limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "gender",        limit: 191
    t.string   "business_name", limit: 191
  end

  add_index "people", ["stripe_pii_id"], name: "index_people_on_stripe_pii_id", using: :btree

  create_table "plans", force: :cascade do |t|
    t.integer  "amount",               limit: 4
    t.string   "currency",             limit: 191
    t.string   "interval",             limit: 191
    t.integer  "interval_count",       limit: 4
    t.boolean  "stripe_livemode",      limit: 1
    t.string   "name",                 limit: 191
    t.string   "statement_descriptor", limit: 22
    t.integer  "trial_period_days",    limit: 4,   default: 0
    t.integer  "hashtag_id",           limit: 4
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "merchant_id",          limit: 4
    t.integer  "customer_id",          limit: 4
  end

  add_index "plans", ["customer_id"], name: "index_plans_on_customer_id", using: :btree
  add_index "plans", ["merchant_id", "name"], name: "index_plans_on_merchant_id_and_name", unique: true, using: :btree
  add_index "plans", ["merchant_id"], name: "index_plans_on_merchant_id", using: :btree

  create_table "referrers", force: :cascade do |t|
    t.string   "referrer_email", limit: 191
    t.string   "email",          limit: 191
    t.string   "phone_number",   limit: 191
    t.integer  "referrer_id",    limit: 4
    t.integer  "referee_id",     limit: 4
    t.string   "country",        limit: 191
    t.string   "postal",         limit: 191
    t.string   "region",         limit: 191
    t.string   "city",           limit: 191
    t.string   "ip",             limit: 191
    t.string   "link",           limit: 191
    t.string   "referrer_name",  limit: 191
    t.string   "org_name",       limit: 191
    t.string   "uid",            limit: 191
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "referrers", ["email"], name: "index_referrers_on_email", using: :btree
  add_index "referrers", ["link"], name: "index_referrers_on_link", using: :btree
  add_index "referrers", ["referee_id"], name: "index_referrers_on_referee_id", using: :btree
  add_index "referrers", ["referrer_email"], name: "index_referrers_on_referrer_email", using: :btree
  add_index "referrers", ["referrer_id"], name: "index_referrers_on_referrer_id", using: :btree
  add_index "referrers", ["uid"], name: "index_referrers_on_uid", using: :btree

  create_table "refunds", force: :cascade do |t|
    t.string   "uri",            limit: 191
    t.string   "time",           limit: 191
    t.string   "reason",         limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transaction_id", limit: 4
  end

  add_index "refunds", ["transaction_id"], name: "index_refunds_on_transaction_id", using: :btree

  create_table "saved_replies", force: :cascade do |t|
    t.string   "title",      limit: 191
    t.text     "body",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "user_id",    limit: 4
  end

  add_index "saved_replies", ["user_id"], name: "index_saved_replies_on_user_id", using: :btree

  create_table "stripe_creds", force: :cascade do |t|
    t.string   "secret",            limit: 191
    t.string   "publishable_key",   limit: 191
    t.string   "uid",               limit: 191
    t.string   "scope",             limit: 191
    t.boolean  "livemode",          limit: 1
    t.string   "refresh_token",     limit: 191
    t.integer  "user_id",           limit: 4
    t.integer  "uid_type",          limit: 4
    t.string   "ip",                limit: 191
    t.integer  "tos_date",          limit: 4
    t.string   "user_agent",        limit: 191
    t.boolean  "charges_enabled",   limit: 1
    t.boolean  "transfers_enabled", limit: 1
    t.string   "disabled_reason",   limit: 191
    t.integer  "due_by",            limit: 4
    t.string   "fields_needed",     limit: 191
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "account_id",        limit: 191
  end

  add_index "stripe_creds", ["uid"], name: "index_stripe_creds_on_uid", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.string   "stripe_subscription_id",  limit: 191
    t.integer  "plan_id",                 limit: 4
    t.integer  "coupon_id",               limit: 4
    t.decimal  "application_fee_percent",             precision: 8, scale: 2
    t.string   "source",                  limit: 191
    t.integer  "quantity",                limit: 4,                           default: 1
    t.string   "tax_percent",             limit: 191
    t.integer  "current_period_start",    limit: 4
    t.integer  "current_period_end",      limit: 4
    t.integer  "canceled_at",             limit: 4
    t.boolean  "cancel_at_period_end",    limit: 1
    t.integer  "ended_at",                limit: 4
    t.integer  "trial_start",             limit: 4
    t.integer  "trial_end",               limit: 4
    t.string   "status",                  limit: 191
    t.boolean  "stripe_livemode",         limit: 1
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
    t.integer  "merchant_customer_id",    limit: 4
  end

  add_index "subscriptions", ["coupon_id"], name: "fk_rails_ddc53c9490", using: :btree
  add_index "subscriptions", ["plan_id"], name: "fk_rails_fc223f21da", using: :btree

  create_table "transactions", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transaction_type",                   limit: 4
    t.decimal  "amount",                                           precision: 8, scale: 2
    t.decimal  "amount_with_taxes",                                precision: 8, scale: 2
    t.string   "tax_percent",                        limit: 191
    t.decimal  "application_fee",                                  precision: 8, scale: 2
    t.decimal  "amount_less_fees",                                 precision: 8, scale: 2
    t.string   "txn_uri",                            limit: 191
    t.string   "txn_number",                         limit: 191
    t.string   "description",                        limit: 191
    t.string   "status",                             limit: 191
    t.string   "txn_available_at",                   limit: 191
    t.string   "last4",                              limit: 191
    t.string   "exp_month",                          limit: 191
    t.string   "exp_year",                           limit: 191
    t.string   "card_type",                          limit: 191
    t.string   "card_name",                          limit: 191
    t.string   "destination",                        limit: 191
    t.integer  "referenced_user_id",                 limit: 4
    t.string   "referenced_customer_transaction_id", limit: 191
    t.string   "receipt_sent_at",                    limit: 191
    t.integer  "user_id",                            limit: 4
    t.text     "notes",                              limit: 65535
    t.integer  "referenced_merchant_transaction_id", limit: 4
    t.integer  "team_id",                            limit: 4
    t.string   "currency",                           limit: 191
    t.integer  "hashtag_id",                         limit: 4
    t.integer  "subscription_id",                    limit: 4
    t.boolean  "captured",                           limit: 1,                             default: true
    t.integer  "merchant_customer_id",               limit: 4
  end

  add_index "transactions", ["created_at"], name: "index_transactions_on_created_at", using: :btree
  add_index "transactions", ["hashtag_id"], name: "index_transactions_on_hashtag_id", using: :btree
  add_index "transactions", ["referenced_customer_transaction_id"], name: "index_transactions_on_referenced_customer_transaction_id", using: :btree
  add_index "transactions", ["subscription_id"], name: "index_transactions_on_subscription_id", using: :btree
  add_index "transactions", ["team_id"], name: "fk_rails_0e0853dbc8", using: :btree
  add_index "transactions", ["txn_number"], name: "index_transactions_on_txn_number", using: :btree
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

  create_table "user_lists", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "list_id",    limit: 4
  end

  add_index "user_lists", ["user_id"], name: "index_user_lists_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 191
    t.string   "encrypted_password",     limit: 191
    t.string   "reset_password_token",   limit: 191
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,     default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 191
    t.string   "last_sign_in_ip",        limit: 191
    t.string   "confirmation_token",     limit: 191
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 191
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_level",             limit: 4
    t.string   "customer_uri",           limit: 191
    t.string   "card_token",             limit: 191
    t.string   "livemode",               limit: 191
    t.string   "last4",                  limit: 191
    t.string   "exp_month",              limit: 191
    t.string   "exp_year",               limit: 191
    t.string   "card_name",              limit: 191
    t.string   "card_type",              limit: 191
    t.string   "phone_number",           limit: 191
    t.string   "org_name",               limit: 191
    t.string   "org_type",               limit: 191
    t.string   "org_category",           limit: 191
    t.string   "org_phone",              limit: 191
    t.string   "org_tax_id",             limit: 191
    t.string   "street_address",         limit: 191
    t.string   "city",                   limit: 191
    t.string   "state_province",         limit: 191
    t.string   "country",                limit: 191
    t.text     "description",            limit: 65535
    t.string   "use_rhombus_for",        limit: 191
    t.string   "rhombus_number",         limit: 191
    t.string   "rn_type",                limit: 191
    t.string   "rn_country",             limit: 191
    t.string   "tax_percent",            limit: 191
    t.integer  "transactions_count",     limit: 4
    t.string   "zip_code",               limit: 191
    t.string   "provider",               limit: 191
    t.string   "uid",                    limit: 191
    t.string   "stripe_access_token",    limit: 191
    t.string   "stripe_publishable_key", limit: 191
    t.string   "stripe_scope",           limit: 191
    t.string   "stripe_refresh_token",   limit: 191
    t.string   "first_name",             limit: 191
    t.string   "last_name",              limit: 191
    t.boolean  "is_active",              limit: 1,     default: true
    t.string   "referrer_num",           limit: 191
    t.string   "url",                    limit: 191
    t.text     "custom_welcome",         limit: 65535
    t.string   "short_url",              limit: 191
    t.string   "currency",               limit: 191
    t.string   "time_zone",              limit: 191,   default: "Eastern Time (US & Canada)"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["phone_number"], name: "index_users_on_phone_number", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["rhombus_number"], name: "index_users_on_rhombus_number", unique: true, using: :btree

  add_foreign_key "alerts", "users"
  add_foreign_key "campaign_lists", "campaigns"
  add_foreign_key "campaign_lists", "lists"
  add_foreign_key "campaign_user_lists", "campaigns"
  add_foreign_key "campaign_user_lists", "users"
  add_foreign_key "coupons", "users"
  add_foreign_key "fb_messages", "campaigns"
  add_foreign_key "fb_messages", "fb_pages"
  add_foreign_key "hashtags", "users"
  add_foreign_key "invoices", "coupons"
  add_foreign_key "invoices", "subscriptions"
  add_foreign_key "invoices", "transactions"
  add_foreign_key "lists", "users"
  add_foreign_key "message_resolutions", "users"
  add_foreign_key "messages", "hashtags"
  add_foreign_key "refunds", "transactions"
  add_foreign_key "subscriptions", "coupons"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "transactions", "hashtags"
  add_foreign_key "transactions", "subscriptions"
  add_foreign_key "transactions", "users", column: "team_id"
  add_foreign_key "user_lists", "users"
end
