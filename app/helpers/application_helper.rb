module ApplicationHelper

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self, current_user)
    block_given? ? yield(presenter) : presenter
  end

  def render_header_partial
    concat(render 'shared/unauthenticate_header') if !check_params && unauthenticate_controller
    concat(render 'shared/authenticated_header') unless unauthenticate_controller || check_params
  end

  def render_sidebar_partial
    render 'shared/dashboard_sidebar' unless (unauthenticate_controller || check_params) || restrict_other_params
  end

  def restrict_other_params
     (params[:controller] == 'campaigns' && params[:action]=='new' || params[:controller] == 'hashtags' && params[:action]=='new')
  end

  def render_footer_partial
    concat(render 'shared/sign_up') if !check_params && unauthenticate_controller
    render 'shared/unauthenticate_footer' if !check_params && unauthenticate_controller
  end

  def unauthenticate_controller
    (params[:controller]=='static_pages' || params[:controller] == 'contact_forms')
  end

  def check_params
    restricted_actions = ['sessions-new', 'sessions-create', 'registrations-new', 'registrations-create']
    restricted_actions.include?("#{params[:controller]}-#{params[:action]}")
  end
end
