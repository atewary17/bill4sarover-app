class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:mobile_output]

  def index
    @from = params[:from].presence&.to_datetime || 15.days.ago.to_date.beginning_of_day
    @to   = params[:to].presence&.to_datetime   || (Date.today + 15.days).end_of_day

    # Bookings data
    @bookings = Booking.where(
      "check_in >= ? AND check_out <= ?",
      @from,
      @to
    )
    @booking_counts = @bookings.group_by_day(:check_in).count

    # Invoice data
    @invoices = Invoice.where(
      "created_at >= ? AND created_at <= ?",
      @from,
      @to
    )
    @invoice_counts = @invoices.group_by_day(:created_at).count
    
    # Invoice totals
    @total_revenue = @invoices.sum(:total_amount)
    @paid_revenue = @invoices.where(status: :paid).sum(:total_amount)
    @pending_revenue = @invoices.where(status: [:draft, :issued, :partial]).sum(:total_amount)
  end

  def mobile_output
    @booking_counts = Booking.group_by_day(:check_in).count
    @invoice_counts = Invoice.group_by_day(:created_at).count
    render json: { bookings: @booking_counts, invoices: @invoice_counts }
  end

end