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
      get :download_rejected
    end
  end
  resources :channel_ones, only: [:index]
  resources :channel_twos, only: [:index]
  resources :storage, only: [:index, :show]
  get "storage/model/:model_name", to: "storage#show_model", as: :storage_model
end
