module ApplicationHelper

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self, current_user)
    block_given? ? yield(presenter) : presenter
  end

  def render_header_partial
    return render 'shared/unauthenticate_header' if unauthenticate_controller
    return render 'shared/authenticated_header' unless authenticated_pages || campaign_restrict_params
    return render 'shared/docs_header' if relay_docs_pages
    return render 'campaigns/campaign_header' if campaign_restrict_params
    return render 'shared/messaging_header' if messaging_dashboard
  end

  def render_customer_sidebar
    concat(render 'shared/customer_sidebar') if params_controller_action == 'users-customers'
  end

  def render_sidebar_partial
    concat(render 'shared/dashboard_sidebar') unless authenticated_pages || setting_pages || messaging_dashboard
    concat(render 'shared/setting_sidebar') if setting_pages
  end

  def authenticated_pages
     unauthenticate_controller || restrict_devise_actions || relay_docs_pages || link_facebook
  end

  def link_facebook
    params['controller'] == 'link_fb_accounts'
  end

  def add_body_class
    return 'body message' if messaging_dashboard 
    'body'
  end

  def restrict_other_params
    actions = ['campaigns-new', 'hashtags-new', 'hashtags-create']
    actions.include?(params_controller_action)
  end

  def messaging_dashboard
    messaging_params = ['conversations-index']
    messaging_params.include?(params_controller_action)
  end

  def campaign_restrict_params
    restrict_params = ['campaigns-index']
    restrict_params.include?(params_controller_action)
  end

  def render_footer_partial
    return render 'shared/unauthenticate_footer' if unauthenticate_controller
  end

  def render_sign_up_footer
    return render 'shared/sign_up' if unauthenticate_controller
  end

  def unauthenticate_controller
    static_controllers = ['static_pages', 'contact_forms' ]
    static_controllers.include?(params[:controller]) unless relay_docs_pages
  end

  def setting_pages
    settings_action = ['devise/registrations-billing_information', 'devise/registrations-account_setting',
                       'registrations-edit', 'alerts-edit', 'plans-index','users-integrations',
                        'users-managed_acct', 'users-sms_usage', 'lists-segments']
    settings_action.include?(params_controller_action)
  end

  def relay_docs_pages
    controller_actions = ['static_pages-relay_docs', 'static_pages-creating_campaigns_in_relay']
    controller_actions.include?(params_controller_action)
  end

  def params_controller_action
    "#{params[:controller]}-#{params[:action]}"
  end

  def restrict_devise_actions
    restricted_actions = ['sessions-new', 'sessions-create', 'registrations-new', 'registrations-create',
                           'devise/registrations-edit', 'devise/passwords-new']
    restricted_actions.include?(params_controller_action)
  end
end
