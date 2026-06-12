class Invoice < ApplicationRecord
  has_many :invoice_bookings, dependent: :destroy
  has_many :bookings, through: :invoice_bookings
  has_many :invoice_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true

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

  def total_paid
    payments.sum(:amount)
  end

  def balance_due
    total_amount - total_paid
  end

  def fully_paid?
    balance_due <= 0
  end

  def has_payments?
    payments.any?
  end
end