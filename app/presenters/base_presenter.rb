class BasePresenter < SimpleDelegator

  # might need to send user and template for partials in here
  def initialize(model, view, user)
    @model, @view, @user = model, view, user
    super(@model)
  end

  def h
    @view
  end
end
