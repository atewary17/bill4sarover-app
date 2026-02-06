class Room < ApplicationRecord
    has_many :bookings
   
    ROOM_TYPES = %w[Classic_Harmony Regal_Harmony Classic_Residence Banquet]
    STATUSES = %w[available occupied maintenance]

    validates :room_number, presence: true, uniqueness: true
    validates :room_type, inclusion: { in: ROOM_TYPES }
    validates :status, inclusion: { in: STATUSES }
    validates :base_price_per_night, numericality: { greater_than: 0 }
end
