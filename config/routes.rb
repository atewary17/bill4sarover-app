Rails.application.routes.draw do
  get 'invoices/index'
  get 'invoices/show'
  get 'invoices/new'
  get 'invoices/create'
  get 'invoices/edit'
  get 'invoices/update'
  get 'invoices/destroy'

  
  resources :invoices do
    member do
      post :issue
      post :record_payment
      post :mark_paid
      post :mark_void
      get :download_pdf
      get :download_receipt
    end
  end

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
  get 'dashboard/mobile_output'
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
      patch :check_in
      patch :check_out
      patch :cancel
    end
  end

  resources :invoices

end
