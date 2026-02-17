class CreateInvoiceBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :invoice_bookings do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true

      t.timestamps
    end
  end
end
