class Booking < ApplicationRecord
  belongs_to :customer
  belongs_to :room, optional: true

  validate :room_availability

  enum status: {
    booked: 0,
    checked_in: 1,
    checked_out: 2,
    cancelled: 3
  }

  validates :check_in, :check_out, presence: true

  private

  def room_availability
    return if room_id.blank? # banquet booking needs to be updated

    overlapping = Booking
      .where(room_id: room_id)
      .where.not(id: id)
      .where.not(status: [:cancelled, :checked_out, :booked])
      .where("check_in < ? AND check_out > ?", check_out, check_in)

    if overlapping.exists?
      errors.add(:room_id, "is not available for selected dates")
    end
  end

  # Class method for AJAX / API checks
  def self.booked_for_dates?(room_id, check_in, check_out)
    where(room_id: room_id)
      .where.not(status: [:cancelled, :checked_out])
      .where("check_in < ? AND check_out > ?", check_out, check_in)
      .exists?
  end
end
