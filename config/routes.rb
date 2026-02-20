Rails.application.routes.draw do
  # Devise with password recovery enabled
  devise_for :users, skip: [:registrations], controllers: {
    passwords: 'users/passwords'
  }
  
  # Custom user management routes (super_admin only)
  authenticate :user, ->(u) { u.super_admin? } do
    resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
      member do
        patch :reset_password
      end
    end
  end

  resources :rooms do
    member do
      patch :update_price
    end
  end

  patch "dashboard/promote", to: "dashboard#promote", as: :promote_user
  
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

  root "dashboard#index"
end