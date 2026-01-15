class BoqPolicy < ApplicationPolicy
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

  # Custom read-like actions delegate to show?
  alias_method :csv_as_json?, :show?
  alias_method :update_header_row?, :show?
  alias_method :export_boq_csv?, :show?
  alias_method :search?, :index?
  alias_method :parse?, :update?
  alias_method :chat?, :show?

  # Custom write-like actions delegate to update?/create?
  alias_method :update_attributes?, :update?
  alias_method :create_line_items?, :update?
  alias_method :attach_boq?, :create?
  alias_method :detach?, :update?
end
