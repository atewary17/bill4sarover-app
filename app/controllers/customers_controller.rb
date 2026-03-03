class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = current_organization.customers.order(:name)
  end

  def show
    # Customer already set and scoped by before_action
  end

  def new
    @customer = current_organization.customers.new
  end

  def create
    @customer = current_organization.customers.new(customer_params)
    
    if @customer.save
      redirect_to customers_path, notice: "Customer created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Customer already set and scoped by before_action
  end

  def update
    if @customer.update(customer_params)
      redirect_to customers_path, notice: "Customer updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Check if customer has any bookings
    if @customer.bookings.any?
      redirect_to customers_path, alert: "Cannot delete customer with existing bookings"
      return
    end

    @customer.destroy
    redirect_to customers_path, notice: "Customer deleted successfully"
  end

  def search
    q = params[:q]
    @customers = current_organization.customers
                                    .where("name ILIKE ? OR phone ILIKE ?", "%#{q}%", "%#{q}%")
                                    .limit(20)
    render json: @customers
  end

  private

  def set_customer
    @customer = current_organization.customers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to customers_path, alert: "Customer not found or access denied"
  end

  def customer_params
    params.require(:customer).permit(:name, :phone, :email, :is_guest, :payer_id)
  end
end