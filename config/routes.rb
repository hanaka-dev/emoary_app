Rails.application.routes.draw do
  
  # 現在rootはhome
  root "static_pages#home"
  # static_pagesのルーティング
  get '/help',    to: "static_pages#help"
  get '/home',    to: "static_pages#home"
  # usersのルーティング
  get '/signup',  to: "users#new"
  resources :users, only: [:new,:create, :show, :destroy]
  
end
