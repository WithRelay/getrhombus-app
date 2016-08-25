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
  
  resources :contact_forms 
  
  get 'customer_template' => "users#customer_csv_template", constraints: { format: 'csv' }
  get 'transactions/download' => 'transactions#download_csv', constraints: { format: 'csv' }
  match "send_mms_from_dashboard" => 'messages#dashboard_mms', via: [:post]
  get 'json_get_current_user' => 'application#json_get_current_user'
  get "receive_text_message" => 'messages#receive_text_message'
  get "receive_text_message_twilio" => 'messages#receive_text_message_twilio'
  get "receive_voice_twilio" => 'messages#receive_voice_twilio'
  get "receive_delivery_report" => 'messages#receive_delivery_report'
  get "receive_delivery_report_twilio" => 'messages#receive_delivery_report_twilio'
  get "facebook_webhook" => 'static_pages#fb_webhook'
  # post "/facebook_webhook" => 'static_pages#fb_webhook'
  # mount MessageQuickly::Engine, at: "/facebook_webhook"

  ## devise routes
  devise_for :users, :controllers => { registrations: "registrations", omniauth_callbacks: "omniauth_callbacks" }
  devise_scope :user do
    get "signup", :to => "devise/registrations#new"
    get "profile", :to => "devise/registrations#edit"
    get "signin", :to => "devise/sessions#new"
  end
  
  # user routes
  resources :users, :only => :show, param: :id do
    resources :hashtags
    
    member do
      get 'messaging' => 'users#messaging'
      get 'contacts' => 'users#contacts' #(both customers or merchants)
      get 'json_get_latest_active_messaging' => 'users#json_get_latest_active_messaging'
      get 'json_get_user_messages_by_merchant/:user_number' => 'users#json_get_user_messages_by_merchant'
      get 'mark_user_messages_for_merchant_as_read/:user_number' => 'users#mark_user_messages_for_merchant_as_read'
      get 'send_message_from_merchant/:user_number' => 'users#send_message_from_merchant'
      get 'transactions' => 'users#transactions'
      get 'customers' => 'users#customers'
      get 'businesses' => 'users#businesses'
    end
  end 
  
  ## api
  api_version(module: "Api::V1", path: {value: "v1"}, constraints: { subdomain: "api" }, defaults: { format: "json" }) do
    match 'users/find' => 'users#find', via: :get
    match 'users/add_customers' => 'users#add_customers', via: :post
    match 'hashtags/find' => 'hashtags#find', via: :get
    match 'transactions/:charge_id/refund' => 'transactions#refund', via: :post
    match 'numbers/search' => 'numbers#search', via: :get
    #match '/hashtags/create' => 'hashtags#create', via: :post
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
