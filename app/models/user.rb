class User < ApplicationRecord
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :validatable
  
  # Include default devise modules
  devise :database_authenticatable, :rememberable, :validatable, :recoverable
  # Remove :registerable and :recoverable for normal users
  belongs_to :organization

  enum role: {
    super_admin: 0,
    admin: 1,
    staff: 2
  }

  validates :name, presence: true
  validates :role, presence: true
  validates :email, uniqueness: { scope: :organization_id }

  # Helper methods
  def can_manage_users?
    super_admin?
  end

  def can_manage_rooms?
    super_admin?
  end

  def can_manage_bookings?
    super_admin? || admin? || staff?
  end
end