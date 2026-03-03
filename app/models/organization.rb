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
  
  # Use ID in URLs (standard Rails behavior)
  # Don't override to_param
  
  # Generate next invoice number with thread-safe counter
  def next_invoice_number
    prefix = settings&.dig('invoice_prefix') || 'INV'
    date_part = Time.current.strftime('%Y%m%d')
    
    # Increment counter atomically (thread-safe)
    counter = increment!(:invoice_counter).invoice_counter
    
    # Format: PREFIX-YYYYMMDD-00001
    "#{prefix}-#{date_part}-#{counter.to_s.rjust(5, '0')}"
  end
  
  private
  
  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end
end