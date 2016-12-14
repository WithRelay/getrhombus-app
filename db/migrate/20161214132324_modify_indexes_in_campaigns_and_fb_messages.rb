class ModifyIndexesInCampaignsAndFbMessages < ActiveRecord::Migration
  def change
  	# Campaigns
    remove_index :campaigns, :name
    add_index :campaigns, [:user_id, :name], unique: true
    remove_index :campaigns, name: 'index_campaigns_on_id_and_user_id'
    add_index :campaigns, :user_id

    # Fb Messages
    add_index :fb_messages, :user_id
    add_index :fb_messages, :user_id_to

    # Messages, Alerts, Bank Accounts
    add_index :messages, :user_id_to
    add_index :messages, :message_id
    add_index :alerts, :user_id
    add_index :bank_accounts, :user_id

    # CampaignLists
    remove_foreign_key :campaign_lists, :campaigns
    remove_foreign_key :campaign_lists, :lists
    remove_index :campaign_lists, name: 'index_campaign_lists_on_list_id_and_campaign_id'
    add_index :campaign_lists, :list_id
    add_index :campaign_lists, :campaign_id

    #CampaignUserLists
    remove_foreign_key :campaign_user_lists, :campaigns
    remove_foreign_key :campaign_user_lists, :users
    remove_index :campaign_user_lists, name: 'index_campaign_user_lists_on_id_and_user_id_and_campaign_id'
    add_index :campaign_user_lists, :user_id
    add_index :campaign_user_lists, :campaign_id

    #Fb Creds
    add_index :fb_creds, :page_specific_id, unique: true

    # FB Pages
    add_index :fb_pages, :user_id

    # Message Resolutions
    add_index :message_resolutions, :user_id

    # People
    add_index :people, :user_id

    # Stripe Creds
    add_index :stripe_creds, :user_id
    add_index :stripe_creds, :account_id, unique: true

    # Subscriptions
    add_index :subscriptions, :merchant_customer_id
    add_index :subscriptions, :plan_id
	add_index :subscriptions, :coupon_id

	# Transactions
	add_index :transactions, :merchant_customer_id
    add_index :transactions, :team_id

    # User Lists
	add_index :user_lists, :list_id

  end
end
