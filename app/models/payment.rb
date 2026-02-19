class Payment < ApplicationRecord
  belongs_to :invoice

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :paid_at, presence: true
  validates :payment_method, presence: true

  before_validation :set_paid_at, on: :create

  def receipt_number
    "RCP-#{invoice.invoice_number}-#{id}"
  end

  private

  def set_paid_at
    self.paid_at ||= Time.current
  end
end