Rails.application.routes.draw do
  get 'import_files/index'
  # devise_for :users, controllers: {
  #   sessions: "users/sessions"
  # }, skip: [:registrations]
  devise_for :users ,skip: [:registrations]

  root "home#index"
  
  resources :imports, only: [:new, :create]
  resources :import_files, only: [:index, :show] do
    member do 
      get :download
    end
  end
  resources :channel_ones, only: [:index]
  resources :channel_twos, only: [:index]
end
