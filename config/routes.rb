Rails.application.routes.draw do
  get 'orders/index'
  get 'orders/import'
  get 'users/index'
  get 'users/import'
  get 'home/index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "home#index"
  post "/" => "home#index"

  resources :users, only: [:index] do
    collection { post :import }
  end

  resources :orders, only: [:index] do
    collection { post :import }
  end
end
