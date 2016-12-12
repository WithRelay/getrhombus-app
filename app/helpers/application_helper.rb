module ApplicationHelper

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self, current_user)
    if block_given?
      yield(presenter)
    else
      presenter
    end
  end



end
