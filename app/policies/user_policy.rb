class UserPolicy < ApplicationPolicy
  def index?
    user.super_admin?
  end

  def show?
    user.super_admin?
  end

  def create?
    user.super_admin?
  end

  def new?
    create?
  end

  def update?
    user.super_admin?
  end

  def edit?
    update?
  end

  def destroy?
    user.super_admin? && record != user # Can't delete yourself
  end

  def reset_password?
    user.super_admin?
  end

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end