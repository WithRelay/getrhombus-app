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
      redirect_to user_path(current_user), notice: 'success'
    else
      redirect_to user_path(current_user), error: 'fail'
    end
  end

  def unsubscribe_user_fb_page(page_id)
    page = FbPage.find_by_id page_id
    if page.present?
      response = FacebookMessengerService.unsubscribe(page.page_access_token)
      if(response['success'])
        page.update_attributes(subscription_status: false)
      end
      redirect_to user_path(current_user), notice: 'success'
    else
      redirect_to user_path(current_user), error: 'fail'
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
    redirect_to user_path(current_user), notice: 'success'
  end

  private 

  def check_user_present
    unless current_user.present?
      redirect_to signin_path
    end
    unless current_user.fb_cred.present?
      redirect_to user_path(current_user)
    end
  end

end
