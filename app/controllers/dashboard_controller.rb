class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:mobile_output]

  def index
    @from = params[:from].presence&.to_datetime || 15.days.ago.to_date.beginning_of_day
    @to   = params[:to].presence&.to_datetime   || (Date.today + 15.days).end_of_day

    # Bookings data - scoped to current organization
    @bookings = current_organization.bookings.where(
      "check_in >= ? AND check_out <= ?",
      @from,
      @to
    )
    @booking_counts = @bookings.group_by_day(:check_in).count

    # Invoice data - scoped to current organization
    @invoices = current_organization.invoices.where(
      "created_at >= ? AND created_at <= ?",
      @from,
      @to
    )
    @invoice_counts = @invoices.group_by_day(:created_at).count
    
    # Invoice totals - scoped to current organization
    @total_revenue = @invoices.sum(:total_amount)
    @paid_revenue = @invoices.where(status: :paid).sum(:total_amount)
    @pending_revenue = @invoices.where(status: [:draft, :issued, :partial]).sum(:total_amount)
    
    # Quick stats
    @total_bookings = @bookings.count
    @total_invoices = @invoices.count
    @total_customers = current_organization.customers.count
    @total_rooms = current_organization.rooms.count
    
    # Status breakdown
    @bookings_by_status = @bookings.group(:status).count
    @invoices_by_status = @invoices.group(:status).count
  end

  def mobile_output
    # For mobile output, scope to current user's organization
    if current_user
      @booking_counts = current_organization.bookings.group_by_day(:check_in).count
      @invoice_counts = current_organization.invoices.group_by_day(:created_at).count
    else
      # If no user logged in, return empty data
      @booking_counts = {}
      @invoice_counts = {}
    end
    
    render json: { 
      bookings: @booking_counts, 
      invoices: @invoice_counts 
    }
  end
end