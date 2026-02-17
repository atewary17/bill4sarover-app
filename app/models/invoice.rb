class Invoice < ApplicationRecord
  has_many :invoice_bookings, dependent: :destroy
  has_many :bookings, through: :invoice_bookings
  has_many :invoice_items, dependent: :destroy

  enum status: {
    draft: "draft",
    issued: "issued",
    partial: "partial",
    paid: "paid",
    void: "void"
  }

  enum discount_type: {
    percentage: "percentage",
    flat: "flat"
  }, _prefix: true

  validates :invoice_number, presence: true, uniqueness: true
end
