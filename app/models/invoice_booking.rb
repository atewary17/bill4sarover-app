class InvoiceBooking < ApplicationRecord
  belongs_to :invoice
  belongs_to :booking

  validates :booking_id, uniqueness: { scope: :invoice_id }
end
