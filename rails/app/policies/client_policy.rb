class ClientPolicy < ApplicationPolicy
  def index?
    not_material_buyer?
  end

  def show?
    not_material_buyer?
  end

  def contacts?
    show?
  end

  def create?
    not_material_buyer?
  end

  def update?
    not_material_buyer?
  end

  def destroy?
    user.admin_role?
  end

  private

  def not_material_buyer?
    !user.material_buyer_role?
  end
end
