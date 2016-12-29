  module FbPageHelper
  def subscribed_page
    page_name = ''
    fb_pages = current_user.fb_pages
    fb_pages.each do |page|
      if page.subscription_status
        page_name = page.page_name
        break
      end
    end
    if FbPage.find_by_page_name page_name
      page_name
    else
      page_name = ''
    end
  end
end