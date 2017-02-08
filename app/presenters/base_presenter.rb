class BasePresenter < SimpleDelegator
  include Rails.application.routes.url_helpers

  # might need to send user and template for partials in here
  def initialize(model, view, user)
    @model, @view, @user = model, view, user
    super(@model)
  end

  def h
    @view
  end

  def format_frequency_type
    @model.frequency_type.humanize.titleize
  end

  def to_user_date_time
    @model.date_time.in_time_zone(@user.time_zone) if @model.date_time.present?
  end

  def format_created_at
    h.time_ago_in_words(@model.created_at) + ' ago'
  end

  def profile_image

      profile_pic = User.check_profile_picture(@model.user)
    if profile_pic[:type] == "image"
          html = h.image_tag(profile_pic[:value], class: 'table-profile-picture', width: 24)
          html = h.image_tag(profile_pic[:value], class: 'campaigns table-profile-picture', width: 24) if @model.class == Hashtag
      elsif profile_pic[:type] == "color"
        class_name = "campaigns table-profile-picture radius-color-#{profile_pic[:value]}"
        html = ("<div class='"+class_name+"'></div>").html_safe
    end
    html
  end

  def date_in_word
    @model.created_at.strftime('%B %d, %Y')
  end

end
