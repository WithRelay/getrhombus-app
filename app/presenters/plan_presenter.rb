class PlanPresenter < BasePresenter

  def format_amount
    "#{Toolbox::Decimal.to_2dp(@model.amount.to_f/100)}" if @model.amount.present?
  end

end
