class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy, :reset_password]
  before_action -> { authorize User }

  def index
    # Super admins see all users, others see only their organization
    if current_user.super_admin?
      @users = User.includes(:organization).order(created_at: :desc)
    else
      @users = current_user.organization.users.order(created_at: :desc)
    end
  end

  def new
    @user = User.new
    # Pre-select current organization for non-super-admins
    @user.organization_id = current_user.organization_id unless current_user.super_admin?
  end

  def create
    @user = User.new(user_params)
    
    # Force organization to current user's org if not super_admin
    unless current_user.super_admin?
      @user.organization_id = current_user.organization_id
    end
    
    # Generate random password
    password = SecureRandom.alphanumeric(12)
    @user.password = password
    @user.password_confirmation = password
    
    if @user.save
      # Store password in flash to show to admin
      flash[:notice] = "User created successfully. Password: <strong>#{password}</strong> - Please save this password!".html_safe
      redirect_to users_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Prevent changing organization unless super_admin
    unless current_user.super_admin?
      params[:user].delete(:organization_id)
    end
    
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
    new_password = SecureRandom.alphanumeric(12)
    @user.update(password: new_password, password_confirmation: new_password)
    flash[:notice] = "Password reset successfully. New password: <strong>#{new_password}</strong> - Please save this password!".html_safe
    redirect_to users_path
  end

  private

  def set_user
    if current_user.super_admin?
      @user = User.find(params[:id])
    else
      @user = current_user.organization.users.find(params[:id])
    end
    authorize @user
  end

  def user_params
    permitted = [:name, :email, :role]
    # Only super_admin can change organization
    permitted << :organization_id if current_user.super_admin?
    params.require(:user).permit(*permitted)
  end
end