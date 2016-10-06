# for adding campaign id to messages and fb message
class AddCampaignIdToMessageAndFbMessage < ActiveRecord::Migration
  def change
    add_reference :fb_messages, :campaign, index: true
    add_foreign_key :fb_messages, :campaigns
  end
end
