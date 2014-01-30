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

ActiveRecord::Schema.define(version: 20140129054623) do

  create_table "messages", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "from"
    t.string   "to"
    t.integer  "status_report_req"
    t.string   "message_timestamp"
    t.integer  "message_type"
    t.string   "message_price"
    t.string   "scts"
    t.string   "client_ref"
    t.string   "status"
    t.string   "status_delivery"
    t.string   "network_code"
    t.string   "error_text"
    t.string   "err_code"
    t.integer  "message_code"
    t.integer  "user_id_from"
    t.integer  "user_id_to"
    t.integer  "transaction_id"
    t.string   "messageId"
    t.string   "text"
  end

  add_index "messages", ["transaction_id"], name: "index_messages_on_transaction_id", using: :btree

  create_table "transactions", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transaction_uri"
    t.integer  "transaction_type"
    t.decimal  "amount",                             precision: 8, scale: 2
    t.decimal  "amount_less_fees",                   precision: 8, scale: 2
    t.string   "transaction_number"
    t.string   "description"
    t.string   "from"
    t.string   "to"
    t.string   "status"
    t.string   "transaction_available_at"
    t.string   "last_four"
    t.string   "expiration_month"
    t.string   "expiration_year"
    t.string   "zip_code"
    t.string   "card_type"
    t.string   "card_name"
    t.string   "appear_on_statement_as"
    t.string   "tax_rate"
    t.string   "on_behalf_of_uri"
    t.string   "account_number"
    t.string   "account_type"
    t.string   "account_name"
    t.string   "routing_number"
    t.integer  "referenced_user_id"
    t.string   "referenced_customer_transaction_id"
    t.string   "receipt_sent_at"
    t.string   "refund_reason"
    t.integer  "user_id"
    t.text     "notes"
    t.decimal  "amount_with_taxes",                  precision: 8, scale: 2
    t.integer  "referenced_merchant_transaction_id"
    t.integer  "referenced_merchant_id"
  end

  add_index "transactions", ["referenced_customer_transaction_id"], name: "index_transactions_on_referenced_customer_transaction_id", using: :btree
  add_index "transactions", ["user_id"], name: "index_transactions_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                        default: "",    null: false
    t.string   "encrypted_password",           default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "user_level"
    t.string   "customer_uri"
    t.string   "last_four"
    t.string   "expiration_month"
    t.string   "expiration_year"
    t.string   "zip_code"
    t.string   "card_name"
    t.string   "card_type"
    t.string   "phone_number"
    t.string   "business_name"
    t.string   "business_type"
    t.string   "street_address"
    t.string   "city"
    t.string   "state_province"
    t.string   "business_phone"
    t.string   "country"
    t.string   "rhombus_number"
    t.string   "routing_number"
    t.string   "account_name"
    t.string   "account_number"
    t.string   "account_type"
    t.boolean  "approve_payments_immediately", default: false
    t.string   "tax_rate",                     default: "0"
    t.integer  "transactions_count"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["phone_number"], name: "index_users_on_phone_number", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["rhombus_number"], name: "index_users_on_rhombus_number", unique: true, using: :btree

end
