module ApplicationHelper
  include PrettyDate

  def present(model, presenter_class=nil)
    klass = presenter_class || "#{model.class}Presenter".constantize
    presenter = klass.new(model, self, current_user)
    block_given? ? yield(presenter) : presenter
  end

  def sidebar_name(param)
    sidebar_name_hash = {
                          'reminders-index' => 'Reminder',
                          'saved_replies-index' => 'Saved Replies',
                          'hashtags-index' => 'Hashtags',
                          # 'hashtags-create' => 'Create Hashtags',

                        }
    sidebar_name_hash["#{param}"]
  end

  def todays_date
    Time.current.strftime('%B %d, %Y')
  end

  def total_alerts
    @todays_txns_count + @todays_unread_convs_count
  end

  def render_header_partial
    return render 'shared/docs_header' if relay_docs_pages || privacy_and_terms_pages
    return render 'shared/unauthenticate_header' if unauthenticate_controller && !restrict_static_pages
    return render 'shared/authenticated_header' unless authenticated_pages || campaign_restrict_params
    return render 'campaigns/campaign_header' if campaign_restrict_params
    return render 'shared/messaging_header' if messaging_dashboard
  end

  def header_class
    return 'bg-hero features-alt-hero hero' if "static_pages-features" == params_controller_action
    "static_pages-home" == params_controller_action ? 'default hero' : 'hero use-case'
  end

  # def render_customer_sidebar
  #   concat(render 'shared/customer_sidebar') if params_controller_action == 'users-customers' || params_controller_action == 'merchant_customers-index'
  # end

  def customer_index
    params_controller_action == 'merchant_customers-index'
  end

  def render_sidebar_partial
    return render 'shared/leads_sidebar' if ['merchant_contacts-index'].include?(params_controller_action)
    return render 'shared/customer_sidebar' if customer_index
    concat(render 'shared/dashboard_sidebar') unless authenticated_pages || setting_pages || messaging_dashboard || restrict_other_params
    render 'shared/setting_sidebar' if setting_pages
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
    return render 'shared/unauthenticate_footer' if unauthenticate_controller && !restrict_static_pages
  end

  def render_sign_up_footer
    return render 'shared/sign_up' if unauthenticate_controller
  end

  def unauthenticate_controller
    static_controllers = ['static_pages', 'contact_forms' ]
    static_controllers.include?(params[:controller]) #unless relay_docs_pages
  end

  def restrict_static_pages
    ['static_pages-to_404'].include?(params_controller_action)
  end

  def setting_pages
    settings_action = ['registrations-billing_information', 'registrations-account_settings',
                        'alerts-edit', 'plans-index','registrations-business_settings',
                       'users-integrations', 'users-managed_acct', 'users-sms_usage', 'lists-segments',
                       'coupons-manage_coupons', 'coupons-index', 'coupons-manage_coupons', 'users-refer_business', 'fb_pages-index']
    settings_action.include?(params_controller_action)
  end

  def relay_docs_pages
    controller_actions = ['static_pages-relay_docs', "knowledge_base_categories-show"]
    controller_actions.include?(params_controller_action)
  end

  def privacy_and_terms_pages
    controller_actions = ['static_pages-privacy', 'static_pages-terms']
    controller_actions.include?(params_controller_action)
  end

  def params_controller_action
    "#{params[:controller]}-#{params[:action]}"
  end

  def restrict_devise_actions
    restricted_actions = ['sessions-new', 'sessions-create', 'registrations-new', 'registrations-create',
                           'registrations-edit', 'devise/passwords-new', 'devise/passwords-create', 'registrations-add_card_info',
                           'registrations-add_profile_info', 'registrations-add_subscription',
                           'registrations-add_rhombus_number', 'merchant_customers-show',
                           'devise/passwords-edit', 'devise/passwords-update', ''
                         ]
    restricted_actions.include?(params_controller_action)
  end
end
