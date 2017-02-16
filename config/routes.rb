Rails.application.routes.draw  do

  root 'static_pages#home'
  # Dynamic action for static_controller routes eg: home_page will generate as home-page
  StaticPagesController.action_methods.each do |action|
    unless action=='creating_campaigns_in_relay'
      get action.split('_').join('-') => "static_pages##{action}"
    end
  end

  get 'relay-docs/creating-campaigns-in-relay' => 'static_pages#creating_campaigns_in_relay'
  get "relay-docs-categories/:slug" => "knowledge_base_categories#show"

  devise_for :users, controllers: { registrations: "registrations", omniauth_callbacks: "omniauth_callbacks", sessions: 'sessions' }
  resources :users, only: [:show] do
    devise_scope :user do
      member do
        get 'add-subscription' => 'registrations#add_subscription'
        get 'add-rhombus-number' => 'registrations#add_rhombus_number'
        get 'add-profile-info' => 'registrations#add_profile_info'
        get 'add-card-info' => 'registrations#add_card_info'
        get "signup", to: "registrations#new"
        get "profile", to: "registrations#edit"
        get "signin", to: "devise/sessions#new"
        patch "update", to: "registrations#update"
      end
    end
  end

  #authenticate :user, -> (user) { CheckUser::RouteAuthentication.new(user).should_authenticate? } do
    post 'lists/create_new_list' => 'lists#create_new_list'
    get 'user_lists/remove_user' => 'user_lists#remove_user'
    get 'fb_pages/remove_integration' => 'fb_pages#remove_integration'
    get 'link_facebook' => 'link_fb_accounts#link_facebook'
    get 'get_current_user' => 'application#get_current_user'
    get 'manage-coupons' => 'coupons#manage_coupons'
    post 'redirect' => 'link_fb_accounts#redirect'

    resources :lists do
      resources :customer_lists
    end

    get "homepage_referrer" => 'referrers#homepage_referrer'
    get "resque" => Resque::Server, anchor: false, constraints: lambda { |req|
      req.env['warden'].authenticated? and req.env['warden'].user.id == 23
    }

    # events/hooks routess
    # constraints subdomain: 'hooks' do
    post 'events/stripe' => 'webhooks#stripe_events'
    post 'events/twilio' => 'webhooks#twilio_events'
    match'events/nexmo' => 'webhooks#nexmo_events', via: [:get, :post]
    match 'events/facebook' => 'webhooks#facebook_events', via: [:get, :post]
    # end

    ## devise routes
    devise_scope :user do
      get "billing-information", to: "registrations#billing_information"
      get "business-setting", to: "registrations#business_setting"
      get "account-setting", to: "registrations#account_setting"
    end

    resources :referrers, only: [:new, :create]

    # user routes
    resources :users, only: :show do
      member do  
        get 'customers' => 'merchant_customers#customers'
        get 'customers/:id' => 'merchant_customers#show' 
      end

      devise_scope :user do
        member do
          get 'segments' => 'lists#segments'
          get 'sms-usage' => 'users#sms_usage'
        end
      end
      resources :fb_pages, only: [:index]
      patch 'update_fb_page' => 'fb_pages#update_user_fb_page'
      resources :hashtags, except: [:show]
      resources :subscriptions, only: [:index, :update, :destroy]

      authenticate :user, -> (user) { user.is_platform? } do
        resources :knowledge_base_categories, param: :slug, only: [:index, :edit, :update, :new, :create]
      end
      resources :plans, only: [:index, :destroy]
      resources :alerts, only: [:update]
      resources :saved_replies
      resources :bank_accounts
      resources :addresses
      resources :people
      resources :transactions do
        collection do
          get 'download' => 'transactions#download_csv', constraints: { format: 'csv' }
        end
      end

      # authenticate resources if a user is merchant
      authenticate :user, -> (user) { user.is_merchant? } do
        resources :conversations, only: [:index]
        resources :campaigns, except: [:show] { collection { get 'filter_campaign' } }
        resources :reminders, except: [:show] { member { put 'change_status' } }
      end

      collection do
        get 'customer_template' => "users#customer_csv_template", constraints: { format: 'csv' }
      end

      # Only admins can create coupons
      resources :coupons
      # , :constraints => lambda { |req| req.env['warden'].authenticated? and req.env['warden'].user.is_platform? }

      member do
        get 'managed-accounts' => 'users#managed_acct'
        match 'managed-accounts' => "users#create_managed_acct", via: :patch
        match 'update-managed-acct' => 'users#update_managed_acct', via: :patch
        get 'businesses' => 'users#businesses'
        get 'notifications' => 'alerts#edit'
        get 'lists' => 'users#lists'
        get 'integrations' => 'users#integrations'
        get 'remove_twitter_integration' => 'users#remove_twitter_integration'
        match 'refer_business' => 'users#refer_business', via: [:get, :post]
      end
    end


    ## api
    api_version(module: "Api::V1", path: { value: "v1"}, constraints: { subdomain: "api" }, defaults: { format: "json" }) do
      resources :users, only: [:index] do
        post 'add_customers', on: :collection
      end
      match 'hashtags' => 'hashtags#index', via: :get
      match 'hashtags/:id/images/:image_id' => 'hashtags#image_delete', via: :delete
      match 'saved_replies' => 'saved_replies#index', via: :get
      post 'saved_replies/edit' => 'saved_replies#edit'
      patch 'saved_replies/update' => 'saved_replies#update'
      post 'saved_replies/create' => 'saved_replies#create'
      # Campaign Routes
      post 'campaigns/change_status' => 'campaigns#change_status'
      post 'campaigns/delete' => 'campaigns#delete_campaign'
      post 'campaigns/check_campaign_name' => 'campaigns#check_campaign_name'
      match 'campaigns/:id/images/:image_id' => 'campaigns#image_delete', via: :delete
      post 'campaigns/send_test_email' => 'campaigns#send_test_email'
      match 'campaigns/upload_images' => 'campaigns#upload_images', via: :post
      match 'campaigns/upload_from_url' => 'campaigns#upload_from_url', via: :post
      #--------------------------------------------------------------------------#
      # reminder routes
      resources :reminders, only: [:create]
      #--------------------------------------------------------------------------#
      match 'transactions/:txn_number/refund' => 'transactions#refund', via: :post
      resources :transactions, only: [:create]
      match 'numbers/search' => 'numbers#search', via: [:get]
      resources :lists, only: [:index, :create]
      resources :coupons, only: [:index, :update] do
        post 'check_coupon_name', on: :collection
      end
      resources :plans, only: [:index, :create, :update] do
        post 'check_plan_name', on: :collection
      end
      resources :subscriptions, only: [:create]
      post 'subscriptions/update_coupon' => 'subscriptions#update_coupon'
      match 'merchant/customers' => 'merchant_customers#customers', via: :get
      match 'referrers/invite_business' => 'referrers#invite_business', via: :post
      resources :demos, only: [:create]
      resources :conversations, only: [:index, :show] do
        get 'find', on: :collection
        member do
          post 'messages'
          post 'mms'
          post 'mark_messages_as_read'
        end
      end
      resources :knowledge_bases, param: :url, only: [:index] do
        get 'rating', on: :member
      end
    end
  #end


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
