Rails.application.routes.draw  do

  ## static pages routes
  root 'static_pages#home'
  get 'about' => 'static_pages#about'
  get 'customers' => 'static_pages#customers'
  get 'faqs' => 'static_pages#faqs'
  get 'privacy' => 'static_pages#privacy'
  get 'terms' => 'static_pages#terms'
  get 'pricing' => 'static_pages#pricing'

  get 'contact' => 'contact_forms#new'

  post 'lists/create_new_list' => 'lists#create_new_list'
  get 'user_lists/remove_user' => 'user_lists#remove_user'
  get 'fb_pages/remove_integration' => 'fb_pages#remove_integration'
  # get 'link_facebook' => 'link_fb_accounts#link_facebook'

  resources :lists do
    resources :customer_lists
  end

  get 'json_get_current_user' => 'application#json_get_current_user'
  get "homepage_referrer" => 'referrers#homepage_referrer'
  get "resque" => Resque::Server, anchor: false, constraints: lambda { |req|
    req.env['warden'].authenticated? and req.env['warden'].user.id == 23
  }

  match "send_mms_from_dashboard" => 'messages#dashboard_mms', via: [:post]
  get 'messaging-dashboard' => 'messages#message_dashboard'

  ## events/hooks routes
  constraints subdomain: "hooks" do
    post 'events/stripe' => 'webhooks#stripe_events'
    match "events/facebook" => "webhooks#facebook_events", via: [:get, :post]

    get "receive_text_message" => 'messages#receive_text_message'
    get "receive_text_message_twilio" => 'messages#receive_text_message_twilio'
    get "receive_voice_twilio" => 'messages#receive_voice_twilio'
    get "receive_delivery_report" => 'messages#receive_delivery_report'
    get "receive_delivery_report_twilio" => 'messages#receive_delivery_report_twilio'
  end

  ## devise routes
  devise_for :users, controllers: { registrations: "registrations", omniauth_callbacks: "omniauth_callbacks", sessions: 'sessions' }
  devise_scope :user do
    get "signup", to: "devise/registrations#new"
    get "profile", to: "devise/registrations#edit"
    get "signin", to: "devise/sessions#new"
  end

  resources :contact_forms
  resources :referrers, only: [:new, :create]
  resources :refunds, :only => :create

  # user routes
  resources :users, only: :show do
    resources :fb_pages, only: [:index]
    patch 'update_fb_page' => 'fb_pages#update_user_fb_page'
    resources :hashtags, except: [:show, :destroy]
    resources :subscriptions, except: [:show, :edit, :update]
    resources :plans, only: [:create, :index, :new]
    resources :alerts, only: [:update]
    resources :saved_replies, only: [:new, :create, :index, :destroy]
    resources :bank_accounts
    resources :addresses
    resources :people
    resources :transactions do

      collection do
        get 'download' => 'transactions#download_csv', constraints: { format: 'csv' }
      end
    end

    collection do
      get 'customer_template' => "users#customer_csv_template", constraints: { format: 'csv' }
    end

    # Only admins can create coupons
    resources :coupons, :constraints => lambda { |req|
      req.env['warden'].authenticated? and req.env['warden'].user.email == '<redacted_email>' #Rails.application.secrets.dashboard_email
    }

    member do
      get 'managed-accounts' => 'users#managed_acct'
      match 'managed-accounts' => "users#create_managed_acct", via: :patch
      get 'messaging' => 'users#messaging'
      get 'contacts' => 'users#contacts' #(both customers or merchants)
      get 'json_get_latest_active_messaging' => 'users#json_get_latest_active_messaging'
      get 'json_get_user_messages_by_merchant/:user_number' => 'users#json_get_user_messages_by_merchant'
      get 'mark_user_messages_for_merchant_as_read/:user_number' => 'users#mark_user_messages_for_merchant_as_read'
      get 'send_message_from_merchant/:user_number' => 'users#send_message_from_merchant'
      get 'customers' => 'users#customers'
      get 'businesses' => 'users#businesses'
      get 'notifications' => 'alerts#edit'
      get 'lists' => 'users#lists'
    end
  end


  # authenticate campaigns resources if a user is merchant
  authenticate :user, -> (user) { user.is_merchant? } do
    resources :campaigns, except: [:show] do
      member do
        put 'change_status'
      end
    end
  end

  ## api
  api_version(module: "Api::V1", path: {value: "v1"}, constraints: { subdomain: "api" }, defaults: { format: "json" }) do
    match 'users/find' => 'users#find', via: :get
    match 'users/add_customers' => 'users#add_customers', via: :post
    match 'hashtags/find' => 'hashtags#find', via: :get
    match 'hashtags/:id/image_delete' => 'hashtags#image_delete', via: :post
    match 'campaigns/:id/image_delete' => 'campaigns#image_delete', via: :post
    match 'campaigns/upload_images' => 'campaigns#upload_images', via: :post
    match 'transactions/:charge_id/refund' => 'transactions#refund', via: :post
    match 'transactions/charge_customer' => 'transactions#charge_customer', via: :post
    match 'numbers/search' => 'numbers#search', via: :get
  end

  ## catch all other to 404
  get "/*other", to: 'static_pages#to_404'     #all non-existent routes go to 404


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

end
