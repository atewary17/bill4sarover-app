class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :room, null: true, foreign_key: true
      t.datetime :check_in
      t.datetime :check_out
      t.integer :adults
      t.integer :children
      t.integer :status

      t.timestamps
    end
  end
end
