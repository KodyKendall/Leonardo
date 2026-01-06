class MonthlyMaterialSupplyRatePolicy < ApplicationPolicy
  def create?
    user.admin_role?
  end

  def update?
    user.admin_role?
  end

  def destroy?
    user.admin_role?
  end

  def save_rate?
    user.admin_role?
  end

  def set_2nd_cheapest_as_winners?
    user.admin_role?
  end
end
