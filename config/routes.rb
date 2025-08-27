Rails.application.routes.draw do
  get 'sessions/new'
  

  root "sessions#new"
  # static_pagesのルーティング
  get '/help',      to: "static_pages#help"
  get '/home',      to: "static_pages#home"
  # usersのルーティング
  get '/signup',    to: "users#new"
  get '/settings',  to: "users#show"
  #sessionsのルーティング
  get '/login',     to: "sessions#new"
  post '/login',    to: "sessions#create"
  delete '/logout', to: "sessions#destroy"
  
  resources :users, only: [:new,:create, :show, :destroy, :edit]
  
end
