class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :source, polymorphic: true, optional: true

  validates :description, presence: true
  validates :quantity, :unit_price, presence: true
end
