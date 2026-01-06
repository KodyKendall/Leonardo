class CraneRatePolicy < ApplicationPolicy
  def create?
    user.admin_role?
  end

  def update?
    user.admin_role?
  end

  def destroy?
    user.admin_role?
  end
end
