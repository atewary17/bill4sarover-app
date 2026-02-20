class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy, :reset_password]
  before_action -> { authorize User }

  def index
    @users = User.all.order(created_at: :desc)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.hex(8) # Generate random password
    
    if @user.save
      redirect_to users_path, notice: "User created successfully. Password: #{@user.password}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: "User updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: "You cannot delete yourself"
      return
    end

    @user.destroy
    redirect_to users_path, notice: "User deleted successfully"
  end

  def reset_password
    new_password = SecureRandom.hex(8)
    @user.update(password: new_password)
    redirect_to users_path, notice: "Password reset successfully. New password: #{new_password}"
  end

  private

  def set_user
    @user = User.find(params[:id])
    authorize @user
  end

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end
end