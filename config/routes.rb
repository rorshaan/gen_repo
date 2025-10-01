Rails.application.routes.draw do
  root "home#index"
  # get 'import_files/index'
  devise_for :users ,skip: [:registrations]



  # Api Only
  namespace :api do
    namespace :v1 do
      devise_for :users,
        skip: [:registrations, :passwords],  # 🚨 no signup/reset in API
        path: '',
        path_names: {
          sign_in: 'login',
          sign_out: 'logout'
        },
        controllers: {
          sessions: 'api/v1/sessions'
        }
    end
  end
  
  resources :imports, only: [:new, :create]

  namespace :api do
    namespace :v1 do
      resources :imports, only: [:new, :create]
    end
  end

  resources :import_files, only: [:index, :show] do
    member do 
      get :download
      get :download_rejected
    end
  end

  namespace :api do
    namespace :v1 do
      resources :import_files, only: [:index, :show] do
        member do
          get :download
          get :download_rejected
        end
      end
    end
  end

  resources :storage do
    collection do
      get :channel_one_hierarchy
      get :channel_one_month
    end
  end
  get "storage/model/:model_name", to: "storage#show_model", as: :storage_model

  resources :records, only: [:index]
  namespace :api do
    namespace :v1 do
      resources :records, only: [:index]
    end
  end
end
