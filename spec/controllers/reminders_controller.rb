require 'rails_helper'

RSpec.describe RemindersController, type: :controller do
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
    let(:reminder_params) { FactoryGirl.attributes_for(:reminder)
    before(:each){ post :create, user_id: merchant_user1, reminder: reminder_params }

    describe '.create' do
      it 'creates a resource campaign with channel sms and frequency type one time' do
        expect(response).to redirect_to(edit_user_campaign_path(merchant_user1, assigns(:reminder)))
      end
    end
  end
end
