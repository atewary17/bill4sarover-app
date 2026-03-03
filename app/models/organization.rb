class Organization < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :customers, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :invoices, dependent: :destroy
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :currency, presence: true
  
  before_validation :generate_slug, on: :create
  
  scope :active, -> { where(active: true) }
  
  def to_param
    slug
  end
  
  private
  
  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end
end