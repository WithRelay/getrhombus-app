# User can select facebook pages 
class FbPagesController < ApplicationController

  def index
    @user_fb_pages = current_user.fb_pages
  end

  def update_user_fb_page
    page = FbPage.find_by_id params["select_page"]
    if page.present?
      page.update_attributes(subscription_status: true)
      redirect_to user_path(current_user), notice: 'success'
    else
      redirect_to user_path(current_user), error: 'fail'
    end
  end
end
