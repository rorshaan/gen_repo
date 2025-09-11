Rails.application.routes.draw do
  # devise_for :users, controllers: {
  #   sessions: "users/sessions"
  # }, skip: [:registrations]
  devise_for :users ,skip: [:registrations]

  root "home#index"
  
  resources :imports, only: [:new, :create]
  resources :channel_ones, only: [:index]
  resources :channel_twos, only: [:index]
end
