class UserPresenter
  
  # http://bamboo-blog-assets.s3.amazonaws.com/presenters_and_conductors_presentation.pdf
  # http://blog.jayfields.com/2007/03/rails-presenter-pattern.html
  # http://nithinbekal.com/posts/rails-presenters/
  # https://www.new-bamboo.co.uk/blog/2007/08/31/presenters-conductors-on-rails/
  # http://blog.nhocki.com/2012/05/08/mixing-presenters-and-helpers/
  def initialize(user)
    @user = user
  end
  attr_reader :user

  def signup_date
    if CONFIG.date_format == :us
      self.user.created_at.strftime('%m/%d/%y')
    elsif CONFIG.date_format == :rest_of_the_world
      self.user.created_at.strftime('%d/%m/%y')
    end
  end

end