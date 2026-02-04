class Booking < ApplicationRecord
  belongs_to :customer
  belongs_to :room, optional: true

  enum status: {
    booked: 0,
    checked_in: 1,
    checked_out: 2,
    cancelled: 3
  }

  validates :check_in, :check_out, presence: true
end
