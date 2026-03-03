class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :edit, :update, :update_price, :destroy]
  before_action -> { authorize @room || Room }

  def index
    @rooms = current_organization.rooms.order(:room_number)
  end

  def show
  end

  def new
    @room = current_organization.rooms.new
  end

  def create
    @room = current_organization.rooms.new(room_params)
    
    if @room.save
      redirect_to rooms_path, notice: "Room created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @room.update(room_params)
      redirect_to rooms_path, notice: "Room updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_price
    if @room.update(base_price_per_night: params[:base_price_per_night])
      redirect_to rooms_path, notice: "Price updated successfully"
    else
      redirect_to rooms_path, alert: "Failed to update price"
    end
  end

  def destroy
    if @room.bookings.any?
      redirect_to rooms_path, alert: "Cannot delete room with existing bookings"
      return
    end

    @room.destroy
    redirect_to rooms_path, notice: "Room deleted successfully"
  end

  private

  def set_room
    @room = current_organization.rooms.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to rooms_path, alert: "Room not found or access denied"
  end

  def room_params
    params.require(:room).permit(:room_number, :room_type, :base_price_per_night, :status)
  end
end