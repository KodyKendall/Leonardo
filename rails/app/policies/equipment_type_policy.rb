class EquipmentTypePolicy < ApplicationPolicy
  def index?
    !user.material_buyer_role?
  end

  def show?
    !user.material_buyer_role?
  end

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
