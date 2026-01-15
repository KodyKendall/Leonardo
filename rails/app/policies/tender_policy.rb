class TenderPolicy < ApplicationPolicy
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

  def builder?
    !user.material_buyer_role?
  end

  def report?
    !user.material_buyer_role?
  end

  def tender_inclusions_exclusions?
    !user.material_buyer_role?
  end

  def material_autofill?
    !user.material_buyer_role?
  end

  def quick_create?
    !user.material_buyer_role?
  end

  def update_inclusions_exclusions?
    !user.material_buyer_role?
  end

  def sync_all_inclusions_exclusions?
    !user.material_buyer_role?
  end

  def mirror_boq_items?
    !user.material_buyer_role?
  end
end
