class UserPresenter < BasePresenter
  
  # http://bamboo-blog-assets.s3.amazonaws.com/presenters_and_conductors_presentation.pdf
  # http://blog.jayfields.com/2007/03/rails-presenter-pattern.html
  # http://nithinbekal.com/posts/rails-presenters/
  # https://www.new-bamboo.co.uk/blog/2007/08/31/presenters-conductors-on-rails/
  # http://blog.nhocki.com/2012/05/08/mixing-presenters-and-helpers/
  

  def org_type_on_managed_acct_page
    @user.org_type == 'Individual' ? 'Individual' : 'Company'
  end

  def page_count
    @model.fb_pages.count > 0
  end
end