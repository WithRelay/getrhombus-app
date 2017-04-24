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

  def profile_image
    profile_pic = User.check_profile_picture(@model)
    if profile_pic[:type] == "image"
      html = h.image_tag(profile_pic[:value], class: 'table-profile-picture', width: 50 )
    elsif profile_pic[:type] == "color"
      class_name = "table-profile-picture radius-color-#{profile_pic[:value]}" if @model.class.to_s == 'User'
      html = ("<div class='"+class_name+"'></div>").html_safe
    end
    html
  end

end
