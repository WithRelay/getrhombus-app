module ApplicationHelper

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self, current_user)
    block_given? ? yield(presenter) : presenter
  end

  def check_params
    restricted_actions = ['sessions-new', 'registrations-new']
    restricted_actions.include?("#{params[:controller]}-#{params[:action]}")
  end
end
