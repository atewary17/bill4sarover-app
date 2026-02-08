class DashboardController < ApplicationController
  def index
    @booking_counts = Booking.group_by_day(:check_in).count
  end
end