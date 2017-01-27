module ApplicationHelper

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self, current_user)
    block_given? ? yield(presenter) : presenter
  end

  def render_header_partial
    unless relay_docs_page
      concat(render 'shared/unauthenticate_header') if (!check_params && unauthenticate_controller)
    end
    concat(render 'shared/docs_header') if relay_docs_page
    concat(render 'shared/authenticated_header') unless (unauthenticate_controller || check_params) || campaign_restrict_params || campaign_restrict_params
    concat(render 'campaigns/campaign_header') if campaign_restrict_params
  end

  def render_sidebar_partial
    render 'shared/dashboard_sidebar' unless (unauthenticate_controller || check_params) || restrict_other_params
  end

  def restrict_other_params
    actions = ['campaigns-new', 'hashtags-new']
    actions.include?("#{params[:controller]}-#{params[:action]}")
  end

  def campaign_restrict_params
    restrict_params = ['campaigns-index']
    restrict_params.include?("#{params[:controller]}-#{params[:action]}")
  end

  def relay_docs_page
    doc_actions = ['static_pages-relay_docs', 'hashtags-new']
    doc_actions.include?("#{params[:controller]}-#{params[:action]}")
  end

  def render_footer_partial
    concat(render 'shared/sign_up') if !check_params && unauthenticate_controller
    render 'shared/unauthenticate_footer' if !check_params && unauthenticate_controller
  end

  def unauthenticate_controller
    static_controllers = ['static_pages', 'contact_forms' ]
    static_controllers.include?(params[:controller])
  end

  def check_params
    restricted_actions = ['sessions-new', 'sessions-create', 'registrations-new', 'registrations-create']
    restricted_actions.include?("#{params[:controller]}-#{params[:action]}")
  end
end
