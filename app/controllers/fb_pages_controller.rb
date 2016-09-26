# User can select facebook pages 
class FbPagesController < ApplicationController

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
      if(response["success"])
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
    fb_cred.destroy
    fb_pages.each{|page| page.destroy}
    redirect_to user_path(current_user), notice: 'success'
  end
end
