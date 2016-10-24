# User can select facebook pages 
class FbPagesController < ApplicationController
  before_action :check_user_present

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
    if page.present?
      response = FacebookMessengerService.subscribe(page.page_access_token)
      if(response["success"])
        page.update_attributes(subscription_status: true)
      end
      redirect_to user_fb_pages_path(current_user), flash: { notice: 'Page has been successfully subscribed' }
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
      redirect_to user_fb_pages_path(current_user), flash: { notice: 'Page has been successfully unsubscribed' }
    else
      redirect_to user_fb_pages_path(current_user), flash: { error: 'Something went wrong' }
    end
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
end
