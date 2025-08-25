Rails.application.routes.draw do
  # usersのルーティング
  get '/signup',  to: "users#new"
  
  # static_pagesのルーティング
  get '/help',    to: "static_pages#help"
  get '/home',    to: "static_pages#home"

  # 現在rootはhome
  root "static_pages#home"
end
