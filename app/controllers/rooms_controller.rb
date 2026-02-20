class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :edit, :update, :update_price, :destroy]
  before_action -> { authorize @room || Room }

  def index
    @rooms = Room.all.order(:room_number)
  end

  def show
  end

  def new
    @room = Room.new
  end

  def create
    @room = Room.new(room_params)
    
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
    @room.destroy
    redirect_to rooms_path, notice: "Room deleted successfully"
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:room_number, :room_type, :base_price_per_night, :status)
  end
end