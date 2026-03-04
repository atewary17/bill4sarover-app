class RoomPolicy < ApplicationPolicy
  def index?
    true # Everyone can view rooms
  end

  def show?
    true
  end

  def copy_to_org?
    user.super_admin?
  end

  def create?
    user.super_admin? || user.admin?
  end

  def new?
    create?
  end

  def update?
    user.super_admin? || user.admin?
  end

  def edit?
    update?
  end

  def update_price?
    user.super_admin? || user.admin?
  end

  def destroy?
    user.super_admin?
  end

  class Scope < Scope
    def resolve
      scope.all # Everyone can see all rooms
    end
  end
end