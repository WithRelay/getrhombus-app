require 'rails_helper'

RSpec.describe CampaignsController, type: :controller do
  include Devise::TestHelpers
  let (:merchant_user1) { FactoryGirl.create :merchant_user1 }

  before(:each){ sign_in(merchant_user1); get :new, user_id: merchant_user1 }

  describe '.new' do
    it 'has 200 status code if new view is rendered' do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  describe '.create' do
    it 'creates a resource campaign with channel sms and frequency type one time' do
      list = FactoryGirl.create :list1
      campaign = FactoryGirl.create :campaign, list_name: list.id
      expect(response).to have_http_status(:success)
    end
  end

  describe '.update' do
    it 'updates a resource campaign' do
      
    end
  end
end
