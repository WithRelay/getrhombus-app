module FbPageHelper
  def subscribed_page
    page_name = ''
    current_user.fb_cred.fb_pages.each do |page|
      if page.subscription_status
        page_name = page.page_name
        break
      end
    end
    page_name
  end
end