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

  # Custom actions - users can generate their own profile pic/bio
  def generate_profile_pic?
    user.admin_role? || record == user
  end

  alias_method :generate_profile_pic_form?, :generate_profile_pic?
  alias_method :generate_bio_audio?, :generate_profile_pic?
  alias_method :generate_bio_audio_form?, :generate_profile_pic?
end
