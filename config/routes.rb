Rails.application.routes.draw  do

  root 'static_pages#home'
  
  get "/receive_text_message" => 'messages#receive_text_message'
  get "/receive_delivery_report" => 'messages#receive_delivery_report'

  get '/about' => 'static_pages#about'
  get '/contact' => 'contact_forms#new'
  get '/customers' => 'static_pages#customers'  
  get '/faqs' => 'static_pages#faqs'
  get '/privacy' => 'static_pages#privacy'
  get '/terms' => 'static_pages#terms'
  get '/pricing' => 'static_pages#pricing'

  get '/x' => 'static_pages#x'
  get '/y' => 'static_pages#y'
  get '/z' => 'static_pages#z'
  get '/a' => 'static_pages#a'
  get '/b' => 'static_pages#b'
  get '/c' => 'static_pages#c'
  get '/d' => 'static_pages#d'
  get '/f' => 'static_pages#f'
  get '/g' => 'static_pages#g'
  get '/h' => 'static_pages#h'
  get '/v' => 'static_pages#v'

  #match 'contact' => 'messages#new', :as => 'contact', :via => :get
  #match 'contact' => 'messages#create', :as => 'contact', :via => :post

  devise_for :users, :controllers => {:registrations => "registrations", :omniauth_callbacks => "omniauth_callbacks" }
  
  devise_scope :user do
    get "signup", :to => "devise/registrations#new"
    get "profile", :to => "devise/registrations#edit"
    get "signin", :to => "devise/sessions#new"
  end
  
  resources :users, :only => :show
  get '/users/:id/json_get_latest_active_messaging' => 'users#json_get_latest_active_messaging'
  get '/users/:id/json_get_user_messages_by_merchant/:user_id' => 'users#json_get_user_messages_by_merchant'
  get '/users/:id/mark_user_messages_for_merchant_as_read/:user_id' => 'users#mark_user_messages_for_merchant_as_read'
  get '/users/:id/send_message_from_merchant/:user_id' => 'users#send_message_from_merchant'
  get '/users/:id/messaging' => 'users#messaging', :as => 'dashboard_messaging'
  
  get '/json_get_current_user' => 'application#json_get_current_user'
  
  resources :transactions, :only => :show
  resources :contact_forms

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
