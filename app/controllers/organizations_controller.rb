class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:show, :edit, :update, :destroy]
  before_action -> { authorize Organization }

  def index
    @organizations = Organization.all.order(created_at: :desc)
  end

  def show
    # Statistics for the organization
    @users_count = @organization.users.count
    @customers_count = @organization.customers.count
    @rooms_count = @organization.rooms.count
    @bookings_count = @organization.bookings.count
    @invoices_count = @organization.invoices.count
    @total_revenue = @organization.invoices.where(status: 'paid').sum(:total_amount)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)
    
    if @organization.save
      redirect_to organizations_path, notice: "Organization created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to organizations_path, notice: "Organization updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @organization.users.any?
      redirect_to organizations_path, alert: "Cannot delete organization with existing users"
      return
    end

    @organization.destroy
    redirect_to organizations_path, notice: "Organization deleted successfully"
  end

  private

  def set_organization
    # Simply find by id - Rails will handle this automatically
    @organization = Organization.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to organizations_path, alert: "Organization not found"
  end

  def organization_params
    permitted = params.require(:organization).permit(
      :name, :slug, :email, :phone, :address, :city, :state, 
      :country, :postal_code, :tax_id, :logo_url, :currency, 
      :timezone, :active
    )
    
    # Properly handle settings JSONB column
    if params[:organization][:settings].present?
      settings = {}
      settings['invoice_prefix'] = params[:organization][:settings][:invoice_prefix] if params[:organization][:settings][:invoice_prefix].present?
      settings['default_tax_rate'] = params[:organization][:settings][:default_tax_rate].to_f if params[:organization][:settings][:default_tax_rate].present?
      permitted[:settings] = settings
    end
    
    permitted
  end
end