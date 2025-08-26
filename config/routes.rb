Rails.application.routes.draw do
  get 'sessions/new'
  
  # 現在rootはhome
  root "static_pages#home"
  # static_pagesのルーティング
  get '/help',      to: "static_pages#help"
  get '/home',      to: "static_pages#home"
  # usersのルーティング
  get '/signup',    to: "users#new"
  get '/settings',  to: "users#show"
  #sessionsのルーティング
  get '/login',     to: "sessions#new"
  post '/login',    to: "sesisons#create"
  delete '/logout', to: "sessions#destroy"
  
  resources :users, only: [:new,:create, :show, :destroy]
  
end
