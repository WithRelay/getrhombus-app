class UserPresenter < BasePresenter

  # http://bamboo-blog-assets.s3.amazonaws.com/presenters_and_conductors_presentation.pdf
  # http://blog.jayfields.com/2007/03/rails-presenter-pattern.html
  # http://nithinbekal.com/posts/rails-presenters/
  # https://www.new-bamboo.co.uk/blog/2007/08/31/presenters-conductors-on-rails/
  # http://blog.nhocki.com/2012/05/08/mixing-presenters-and-helpers/

  def org_type_on_managed_acct_page
    @user.org_type == 'Individual' ? 'Individual' : 'Company'
  end

  def render_user_pages
    render_page = render_merchant_page if @user.is_merchant?
    h.render(render_page)
  end

  def render_merchant_page
    return 'business_information' unless merchant_org_present?
    return 'phone_number' unless merchant_rhombus_number_present?
    return 'billing_information' unless merchant_subscription_present?
  end


  def page_count
    @model.fb_pages.count > 0
  end

  private

  def merchant_org_present?
    @user.org_name.present?
  end

  def merchant_rhombus_number_present?
    @user.rhombus_number.present?
  end

  def merchant_subscription_present?
    @user.get_saas_subscription.present?
  end

  def number_org_present?
    merchant_org_present? && merchant_rhombus_number_present?
  end
end
