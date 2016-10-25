# User can select facebook pages 
class FbPagesController < ApplicationController
  before_action :check_user_present, :update_page
  respond_to :html, :js

  def index
    @user_fb_pages = current_user.fb_pages
  end

  def update_user_fb_page
    select_page = params['select_page'].split.first
    if (params['commit'] == 'Subscribe')
      subscribe_user_fb_page(select_page)
    else
      unsubscribe_user_fb_page(select_page)
    end    
  end

  def subscribe_user_fb_page(page_id)
    page = FbPage.find_by_id page_id
    flag = true
    flag = unsubscribe_previous_page if subscribed_page_present?

    if page.present? && flag
      response = FacebookMessengerService.subscribe(page.page_access_token)
      if(response["success"])
        page.update_attributes(subscription_status: true)
      end
      redirect_to user_fb_pages_path(current_user), flash: { notice: page.page_name + ' page has been successfully subscribed' }
    else
      redirect_to user_fb_pages_path(current_user), flash: { error: 'Something went wrong' }
    end
  end

  def unsubscribe_user_fb_page(page_id)
    page = FbPage.find_by_id page_id
    if page.present?
      response = FacebookMessengerService.unsubscribe(page.page_access_token)
      if(response['success'])
        page.update_attributes(subscription_status: false)
      end
      redirect_to user_fb_pages_path(current_user), flash: { notice: page.page_name + ' page has been successfully unsubscribed' }
    else
      redirect_to user_fb_pages_path(current_user), flash: { error: 'Something went wrong' }
    end
  end

  def unsubscribe_previous_page
    res = false
    current_user.fb_cred.fb_pages.each do |page|
      if page.subscription_status
        page = FbPage.find_by_id page.id
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
    response = false
    current_user.fb_cred.fb_pages.each do |page|
      if page.subscription_status
        response = true
      end
    end
    response
  end

  def remove_integration
    fb_cred = current_user.fb_cred
    fb_pages = fb_cred.fb_pages
    response = {}
    if fb_pages.present?
      fb_pages.each do |page|
        if page.subscription_status
          response = FacebookMessengerService.unsubscribe(page.page_access_token)
        end
      end
    end
    if response['success'] || fb_pages.empty? || FbPage.where(subscription_status: true).empty?
      FbCred.where(fb_id: fb_cred.fb_id).destroy_all
    end
    redirect_to user_path(current_user), flash: { notice: 'You have disconnected Facebook Messenger from Rhombus.' }
  end

  private 

  def check_user_present
    if current_user.nil?
      redirect_to signin_path,  flash: { error: 'You are not Signed In' }
    elsif current_user.fb_cred.nil?
      redirect_to user_path(current_user),  flash: { error: 'Your messenger account is not connected with Rhombus' }
    end
  end

  def update_page
    begin
      page_array = FacebookMessengerService.get_page(current_user.fb_cred.auth_token)
      stored_pages = current_user.fb_cred.fb_pages
      remove_deleted_page(stored_pages, page_array)
      page_array.each do |page|
        if stored_pages.find_by_page_id page['id']
          stored_page = stored_pages.find_by_page_id page['id']
          stored_page.update(page_access_token: page['access_token'])
        else
          FbPage.create(page_id: page['id'],
            user_id: current_user.id,
            category: page['category'],
            page_access_token: page['access_token'],
            page_name: page['name'],
            fb_cred_id: current_user.fb_cred.id)
        end
      end
    rescue Exception => e
    end
  end

  def remove_deleted_page(stored_pages, page_array)
    begin
      page_ids = []
      page_array.each{|p| page_ids << p['id']}
      stored_pages.each do |page|
        unless page_ids.include? page.page_id
          page.destroy
        end
      end
    rescue Exception => e
    end
  end
end
