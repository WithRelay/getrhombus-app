# User can select facebook pages 
class FbPagesController < ApplicationController
  before_action :set_data, :check_cred_present, :update_page
  before_action :set_page, only: [:update_user_fb_page]
  respond_to :html, :js

  def index
    @user_fb_pages = current_user.fb_pages
  end

  def update_user_fb_page
    if (params['commit'] == 'Subscribe')
      subscribe_user_fb_page
    else
      unsubscribe_user_fb_page
    end    
  end

  def subscribe_user_fb_page
    res = subscribed_page_present? ? unsubscribe_previous_page : true

    if @fb_page.present? && res
      response = FacebookMessengerService.subscribe(@fb_page.page_access_token)
      if(response["success"])
        @fb_page.update_attributes(subscription_status: true)
      end
      redirect_to user_fb_pages_path(current_user), flash: { notice: @fb_page.page_name + ' page has been successfully subscribed' }
    else
      redirect_to user_fb_pages_path(current_user), flash: { error: 'Something went wrong' }
    end
  end

  def unsubscribe_user_fb_page
    if @fb_page.present?
      response = FacebookMessengerService.unsubscribe(@fb_page.page_access_token)
      if(response['success'])
        @fb_page.update_attributes(subscription_status: false)
      end
      redirect_to user_fb_pages_path(current_user), flash: { notice: @fb_page.page_name + ' page has been successfully unsubscribed' }
    else
      redirect_to user_fb_pages_path(current_user), flash: { error: 'Something went wrong' }
    end
  end

  def unsubscribe_previous_page
    res = false
    @user_fb_pages.each do |page|
      if page.subscription_status
        response = FacebookMessengerService.unsubscribe(page.page_access_token)
        if(response['success'])
          res = true
          page.update_attributes(subscription_status: false)
        end
      end
    end
    res
  end

  def subscribed_page_present?
    @user_fb_pages.subscribed.present?
  end

  def remove_integration
    response = {}
    subscribed_page = @user_fb_pages.subscribed
    # only one page can be subscribed to at a time
    response = FacebookMessengerService.unsubscribe(subscribed_page[0].page_access_token) if subscribed_page.present?
    
    #1. user has pages/subscribed-page and fb returns success - destroy
    #2. user has pages/subscribed-page and fb returns failure - dont destroy
    #3. user has pages but no subscribed-page (no fb call) - destroy
    #4. user has no pages (no fb call) - still destroy for good measure

    # current_user.fb_pages.subscribed.empty? returns true when no page is subscribed
    # in this case response['success'] || fb_pages.blank? returns false
    if response['success'] || @user_fb_pages.blank? || subscribed_page.empty?
      # wipe everythiing (fb_creds, fb_pages) related to the current_user
      @user_fb_pages.destroy_all
      current_user.fb_creds.destroy_all             # oauth fb_cred of current user including page specific fb_creds
      redirect_to user_path(current_user), flash: { notice: 'You have disconnected Facebook Messenger from Rhombus.' }
    else
      redirect_to user_path(current_user), flash: { error: 'Unable to disconnect your Facebook Messenger from Rhombus.' }
    end
  end

  private

  def set_data
    if current_user.nil?
      redirect_to signin_path,  flash: { error: 'You are not Signed In' }
    else 
      @user_fb_pages = current_user.fb_pages
      @fb_cred = current_user.fb_creds.where(page_specific_id: nil)[0]
    end    
  end

  def set_page
    @fb_page = FbPage.find_by id: params['select_page'].split.first
  end

  def check_cred_present
    if @fb_cred.nil?
      redirect_to user_path(current_user),  flash: { error: 'Your facebook account is not connected with Rhombus' }
    end
  end

  def update_page
    begin
      auth_token = @fb_cred.auth_token
      page_array = FacebookMessengerService.get_page(auth_token)
      remove_deleted_page(page_array)
      page_array.each do |page|
        unless @user_fb_pages.find_by_page_id page['id']
          FbPage.create(
            page_id: page['id'],
            user_id: current_user.id,
            category: page['category'],
            page_access_token: page['access_token'],
            page_name: page['name'],
            fb_cred_id: @fb_cred.id
          )
        end
      end
    rescue StandardError => e
    end
  end

  def remove_deleted_page(page_array)
    begin
      page_ids = page_array.map { |p| p['id'] }
      @user_fb_pages.each do |page|
        unless page_ids.include? page.page_id
          page.destroy
        end
      end
    rescue StandardError => e
    end
  end
end
