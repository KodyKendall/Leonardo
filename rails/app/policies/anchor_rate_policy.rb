class AnchorRatePolicy < ApplicationPolicy
  def create?
    user.admin_role? || user.material_buyer_role?
  end

  def update?
    user.admin_role? || user.material_buyer_role?
  end

  def destroy?
    user.admin_role?
  end
end