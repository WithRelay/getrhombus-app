require 'rails_helper'

RSpec.describe CampaignsController, type: :controller do
  include Devise::TestHelpers

  let (:merchant_user1) { FactoryGirl.create :merchant_user1 }
  before(:each){ sign_in(merchant_user1) }

  describe '.new' do
    it 'has 200 status code if new view is rendered' do
      get :new, user_id: merchant_user1
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  describe 'test class method create, edit, update' do
    let(:list) { FactoryGirl.create :list1 }
    let(:campaign_params) { FactoryGirl.attributes_for(:campaign).merge({ list_name: list.id }) }
    before(:each){ post :create, user_id: merchant_user1, campaign: campaign_params }

    describe '.create' do
      it 'creates a resource campaign with channel sms and frequency type one time' do
        expect(response).to redirect_to(edit_user_campaign_path(merchant_user1, assigns(:campaign)))
      end
    end

    describe '.edit' do
      it 'has 200 status code if edit view is rendered' do
        get :edit, user_id: merchant_user1, id: assigns(:campaign)
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end
    end

    describe '.update' do
      it 'updates a specific resource campaign' do
        campaign_params[:name] = FFaker::Lorem.word
        patch :update, user_id: merchant_user1, id: assigns(:campaign), campaign: campaign_params
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(edit_user_campaign_path(merchant_user1, assigns(:campaign)))
      end
    end
  end
end
