class Booking < ApplicationRecord
  belongs_to :organization
  belongs_to :customer
  belongs_to :room, optional: true
  has_many :invoice_bookings, dependent: :destroy
  has_many :invoices, through: :invoice_bookings

  # Set default status before validation
  before_validation :set_default_status, on: :create
  
  validate :room_availability, on: :create
  validate :customer_belongs_to_organization
  validate :room_belongs_to_organization

  enum status: {
    booked: 0,
    checked_in: 1,
    checked_out: 2,
    cancelled: 3,
    invoiced: 4
  }

  validates :check_in, :check_out, presence: true
  validates :status, presence: true
  validates :adults, numericality: { greater_than: 0 }
  validates :children, numericality: { greater_than_or_equal_to: 0 }
  validate :check_out_after_check_in
  
  scope :for_organization, ->(org_id) { where(organization_id: org_id) }

  private

  def set_default_status
    self.status ||= :booked
  end

  def check_out_after_check_in
    return if check_in.blank? || check_out.blank?
    
    if check_out <= check_in
      errors.add(:check_out, "must be after check-in date")
    end
  end

  def customer_belongs_to_organization
    return if customer_id.blank? || organization_id.blank?
    
    unless customer&.organization_id == organization_id
      errors.add(:customer, "does not belong to this organization")
    end
  end

  def room_belongs_to_organization
    return if room_id.blank? || organization_id.blank?
    
    unless room&.organization_id == organization_id
      errors.add(:room, "does not belong to this organization")
    end
  end

  def room_availability
    return if room_id.blank? # Skip for banquet bookings
    return if organization_id.blank?

    # Only check for bookings in the same organization
    overlapping = organization.bookings
                             .where(room_id: room_id)
                             .where.not(id: id)
                             .where.not(status: [:cancelled, :invoiced])
                             .where("check_in < ? AND check_out > ?", check_out, check_in)

    if overlapping.exists?
      errors.add(:room_id, "is not available for selected dates")
    end
  end

  # Class method for AJAX / API checks
  def self.booked_for_dates?(room_id, check_in, check_out)
    where(room_id: room_id)
      .where.not(status: [:cancelled, :invoiced])
      .where("check_in < ? AND check_out > ?", check_out, check_in)
      .exists?
  end
end