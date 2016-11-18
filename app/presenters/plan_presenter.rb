class PlanPresenter < BasePresenter

  def format_amount
    "%.2f" %(@model.amount.to_f/100)  if @model.amount.present?
  end

end
