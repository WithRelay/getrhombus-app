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
end
