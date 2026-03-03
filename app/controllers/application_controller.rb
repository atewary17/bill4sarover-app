class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  before_action :authenticate_user!
  before_action :set_current_organization
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  helper_method :current_organization

  def after_sign_in_path_for(resource)
    root_path
  end
  
  private
  
  def current_organization
    @current_organization ||= current_user&.organization
  end
  
  def set_current_organization
    return unless current_user
    
    # Store organization_id in session for easier access
    session[:organization_id] = current_user.organization_id
  end
  
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end