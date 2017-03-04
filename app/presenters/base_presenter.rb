class BasePresenter < SimpleDelegator
  include Rails.application.routes.url_helpers
  include PrettyDate

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
    h.time_ago_in_words(@model.created_at) + ' ago' if @modal.present?
  end

  def very_short_relative_time
    time_in_relative_form(@model.created_at)
  end

  def profile_image
    profile_pic = User.check_profile_picture(@model.user)
    if profile_pic[:type] == "image"
          html = h.image_tag(profile_pic[:value], class: 'table-profile-picture', width: 24)
          html = h.image_tag(profile_pic[:value], class: 'campaigns table-profile-picture', width: 24) if @model.class == Hashtag
    elsif profile_pic[:type] == "color"
      class_name_value = "table-profile-picture radius-color-#{profile_pic[:value]}"
      class_name = ['Reminder', 'Transaction'].include?(@model.class.to_s) ? class_name_value : "campaigns #{class_name_value}"
      html = ("<div class='"+class_name+"'></div>").html_safe
    end
    html
  end

  def date_in_word
    @model.created_at.strftime('%B %d, %Y')
  end

  def get_plan_intervals
    { "Weekly" => "week_1", "Bi-weekly" => 'week_2',
      "Monthly" => "month_1", "Every 3 months" => 'month_3',
      'Every 6 months' => 'month_6', 'Yearly' => 'year_1' }
  end

end
