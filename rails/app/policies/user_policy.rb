class UserPolicy < ApplicationPolicy
  def index?
    user.admin_role?
  end

  def show?
    user.admin_role? || record == user
  end

  def create?
    user.admin_role?
  end

  def update?
    user.admin_role? || record == user
  end

  def destroy?
    user.admin_role?
  end
end
