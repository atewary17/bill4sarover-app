class CreateRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :rooms do |t|
      t.string :room_number
      t.string :room_type
      t.decimal :base_price_per_night
      t.string :status

      t.timestamps
    end
  end
end
