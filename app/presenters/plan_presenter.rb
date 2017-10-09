class PlanPresenter < BasePresenter

  def format_amount
    "#{Toolbox::Decimal.to_int_or_2dp(@model.amount.to_f/100)}" if @model.amount.present?
  end

  def format_plan_name
    tag = @model.hashtag_tag
    @model.name + (tag.present? ? " (#{tag})" : '')
  end

end
