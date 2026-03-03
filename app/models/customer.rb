class Customer < ApplicationRecord
  belongs_to :organization
  belongs_to :payer, class_name: "Customer", optional: true
  has_many :guests, class_name: "Customer", foreign_key: :payer_id
  has_many :bookings
  
  validates :name, presence: true
  validates :phone, presence: true
  
  scope :for_organization, ->(org_id) { where(organization_id: org_id) }
end