class BookingsController < ApplicationController
  before_action :set_booking, only: [:show, :edit, :update, :check_in, :check_out, :cancel]

  def index
    @from = params[:from].presence&.to_date || 30.days.ago.to_date
    @to = params[:to].presence&.to_date || Date.today

    @bookings = current_organization.bookings
                                   .includes(:customer, :room)
                                   .where("check_in >= ? AND check_in <= ?", 
                                          @from.beginning_of_day, 
                                          @to.end_of_day)
                                   .order(check_in: :desc)
  end

  def show
    # Booking already set and scoped by before_action
  end

  def new
    @booking = current_organization.bookings.new
    
    # Only show rooms from current organization
    @rooms = current_organization.rooms.order(:room_number)
    
    # Only show customers from current organization
    @customers = current_organization.customers.order(:name)
  end

  def create
    @booking = current_organization.bookings.new(booking_params)
    
    if @booking.save
      redirect_to @booking, notice: "Booking created successfully"
    else
      @rooms = current_organization.rooms.order(:room_number)
      @customers = current_organization.customers.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @rooms = current_organization.rooms.order(:room_number)
    @customers = current_organization.customers.order(:name)
  end

  def update
    if @booking.update(booking_params)
      redirect_to @booking, notice: "Booking updated successfully"
    else
      @rooms = current_organization.rooms.order(:room_number)
      @customers = current_organization.customers.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def check_in
    if @booking.booked?
      @booking.checked_in!
      redirect_to @booking, notice: "Booking checked in successfully"
    else
      redirect_to @booking, alert: "Only booked bookings can be checked in"
    end
  end

  def check_out
    if @booking.checked_in?
      @booking.checked_out!
      redirect_to @booking, notice: "Booking checked out successfully"
    else
      redirect_to @booking, alert: "Only checked-in bookings can be checked out"
    end
  end

  def cancel
    if @booking.booked? || @booking.checked_in?
      @booking.cancelled!
      redirect_to @booking, notice: "Booking cancelled successfully"
    else
      redirect_to @booking, alert: "This booking cannot be cancelled"
    end
  end

  def available_rooms
    check_in = params[:check_in].to_date
    check_out = params[:check_out].to_date

    # Get all rooms for this organization
    all_rooms = current_organization.rooms

    # Find bookings that overlap with the requested dates
    conflicting_bookings = current_organization.bookings
                                              .where.not(status: [:cancelled, :invoiced])
                                              .where("check_in < ? AND check_out > ?", check_out, check_in)

    # Get IDs of rooms that are booked
    booked_room_ids = conflicting_bookings.pluck(:room_id)

    # Return rooms that are not booked
    available_rooms = all_rooms.where.not(id: booked_room_ids)

    render json: available_rooms.map { |r| { id: r.id, room_number: r.room_number, room_type: r.room_type } }
  end

  def check_room_status
    room_id = params[:room_id]
    check_in = params[:check_in].to_date
    check_out = params[:check_out].to_date

    # Verify room belongs to current organization
    room = current_organization.rooms.find_by(id: room_id)
    unless room
      render json: { booked: true, error: "Room not found" }
      return
    end

    # Check if room is booked during this period
    booked = current_organization.bookings
                                .where(room_id: room_id)
                                .where.not(status: [:cancelled, :invoiced])
                                .where("check_in < ? AND check_out > ?", check_out, check_in)
                                .exists?

    render json: { booked: booked }
  end

  def room_history
    room_id = params[:room_id]
    
    # Verify room belongs to current organization
    room = current_organization.rooms.find_by(id: room_id)
    unless room
      render json: []
      return
    end

    bookings = current_organization.bookings
                                  .where(room_id: room_id)
                                  .includes(:customer)
                                  .order(check_in: :desc)
                                  .limit(5)

    render json: bookings.map { |b|
      {
        customer: b.customer&.name,
        check_in: b.check_in.strftime("%d %b"),
        check_out: b.check_out.strftime("%d %b"),
        status: b.status
      }
    }
  end

  private

  def set_booking
    @booking = current_organization.bookings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bookings_path, alert: "Booking not found or access denied"
  end

  def booking_params
    params.require(:booking).permit(
      :customer_id, :room_id, :check_in, :check_out,
      :adults, :children, :status, :comment
    )
  end
end