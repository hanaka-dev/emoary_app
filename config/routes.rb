Rails.application.routes.draw do
  get 'password_resets/new'
  get 'password_resets/edit'
  get 'sessions/new'
  

  root "sessions#new"
  # static_pagesのルーティング
  get '/help',        to: "static_pages#help"
  get '/home',        to: "static_pages#home"
  # usersのルーティング
  get '/signup',      to: "users#new"
  get '/settings',    to: "users#show"
  patch '/settings',  to: "users#update"
  delete '/settings', to: "users#destroy"
  #sessionsのルーティング
  get '/login',       to: "sessions#new"
  post '/login',      to: "sessions#create"
  post '/demo_login', to: "sessions#create_demo", as: :demo_login
  post '/demo/purge_extras', to: "demo_extras#create", as: :demo_purge_extras
  delete '/logout',   to: "sessions#destroy"
  
  resources :users, only: [:new,:create, :show, :destroy, :edit, :update]
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: [:new,  :create,  :edit,  :update]

  #diariesのルーティング
  resources :diaries, only: [:new, :create] do
    collection do
      post :confirm
    end
  end
  
end
