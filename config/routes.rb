Rails.application.routes.draw do

  get '/' => 'game#game'
  get 'login' => 'login#login'
  post 'try_login' => 'login#try_login'
  post 'save_formation' => 'api#save_formation'
  get 'load_world' => 'api#load_world'
  get 'history/:season' => 'api#history'
  get 'squad/:id' => 'api#view_team'
  get 'game_events/:id' => 'api#game_events'
  get 'game_events_since/:id/:event_id' => 'api#game_events_since'
  get 'game_events_since/:id/' => 'api#game_events_since'
  get 'tables' => 'api#league_tables'
  get 'fixtures' => 'api#fixtures'
  get 'transfer_listings' => 'api#transfer_listings'
  get 'news_articles' => 'api#news_articles'
  get 'top_scorers' => 'api#top_scorers'
  post 'transfer_bid' => 'api#transfer_bid'
  post 'sell_player' => 'api#sell_player'
  post 'delete_message' => 'api#delete_message'
  post 'got_fcm_token' => 'api#got_fcm_token'
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
