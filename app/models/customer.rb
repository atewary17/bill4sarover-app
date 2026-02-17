class Customer < ApplicationRecord
  has_many :bookings, dependent: :destroy
  belongs_to :payer, class_name: "Customer", optional: true
  has_many :guests, class_name: "Customer", foreign_key: :payer_id
end
