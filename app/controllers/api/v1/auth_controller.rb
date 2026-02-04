class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user!, only: [:me, :logout]

  def login
    user = User.find_by(email: params[:email])
    if user&.valid_password?(params[:password])
      sign_in user
      render json: { user: user }, status: :ok
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end

  def me
    render json: current_user
  end

  def logout
    sign_out current_user
    render json: { message: 'Logged out' }
  end
end
