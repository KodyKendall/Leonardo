class ClientPolicy < ApplicationPolicy
  def index?
    !user.material_buyer_role?
  end

  def show?
    !user.material_buyer_role?
  end

  def create?
    !user.material_buyer_role?
  end

  def update?
    !user.material_buyer_role?
  end

  def destroy?
    user.admin_role?
  end
end
