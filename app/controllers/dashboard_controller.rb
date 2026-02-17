class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:mobile_output]

  def index
    @booking_counts = Booking.group_by_day(:check_in).count
  end

  def mobile_output
    @booking_counts = Booking.group_by_day(:check_in).count
    render json: @booking_counts
  end
end