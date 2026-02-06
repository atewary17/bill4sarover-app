Rails.application.routes.draw do
  
  resources :customers do
    collection do
      get :search
    end
  end

  
  get 'bookings/index'
  get 'bookings/show'
  get 'bookings/new'
  get 'bookings/edit'
  get 'dashboard/index'
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  root "dashboard#index"

  resources :bookings do
    collection do
      get :view_rooms
      get :available_rooms
      get :check_room_status
      get :room_history
    end
    
    member do
      patch :cancel
    end
  end

end
