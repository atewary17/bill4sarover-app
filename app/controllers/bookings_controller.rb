class BookingsController < ApplicationController
  before_action :set_booking, only: %i[ show edit update destroy check_in check_out cancel ]

  def index
    # Default date range: last 30 days to today
    @from = params[:from].presence || 15.days.ago.to_date
    @to   = params[:to].presence || Date.today + 15.days

    @bookings = Booking.includes(:customer, :room).order(check_in: :desc)

    # Apply date filter
    @bookings = @bookings.where(
      "check_in >= ? AND check_out <= ?",
      @from.to_date.beginning_of_day,
      @to.to_date.end_of_day
    )
  end

  def show
  end

  def new
    @check_in  = (params[:to].presence || Time.current).change(sec: 0)

    @booking = Booking.new(
      status: "booked",
    )
  end

  def edit
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.status = "booked"

    if @booking.save
      redirect_to @booking, notice: "Booking created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @booking.update(booking_params)
      redirect_to @booking, notice: "Booking updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @booking.destroy
    redirect_to bookings_path, notice: "Booking deleted successfully"
  end

  def view_rooms
    @rooms = Room.order(:room_number)
  end

  def available_rooms
    check_in = params[:check_in]
    check_out = params[:check_out]

    booked_room_ids = Booking
      .where.not(status: [:cancelled, :checked_out, :booked])
      .where("check_in < ? AND check_out > ?", check_out, check_in)
      .pluck(:room_id)

    @rooms = Room.where.not(id: booked_room_ids)

    render json: @rooms.select(:id, :room_number, :room_type)
  end

  def check_in
    @booking = Booking.find(params[:id])
    @booking.update(status: "checked_in")
    redirect_to @booking, notice: "Guest checked in"
  end

  def check_out
    @booking = Booking.find(params[:id])
    @booking.update(status: "checked_out")
    redirect_to @booking, notice: "Guest checked out"
  end


  def check_room_status
    booked = Booking.booked_for_dates?(
      params[:room_id],
      params[:check_in],
      params[:check_out]
    )
    render json: { booked: booked }
  end

  def cancel
    @booking = Booking.find(params[:id])
    @booking.update(status: :cancelled)

    redirect_to @booking, notice: "Booking cancelled successfully"
  end

  def room_history
    room_id = params[:room_id]
    check_in = params[:check_in]
    check_out = params[:check_out]

    bookings = Booking
      .where(room_id: room_id)
      .where("check_in < ? AND check_out > ?", check_out, check_in)
      .includes(:customer)

    render json: bookings.map { |b|
      {
        id: b.id,
        customer: b.customer.name,
        check_in: b.check_in.strftime("%d %b %Y %H:%M"),
        check_out: b.check_out.strftime("%d %b %Y %H:%M"),
        status: b.status
      }
    }
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(
      :customer_id,
      :room_id,
      :check_in,
      :check_out,
      :adults,
      :children,
      :status,
      :comment 
    )
  end
end
