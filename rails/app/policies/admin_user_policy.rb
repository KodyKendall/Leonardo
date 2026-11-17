# frozen_string_literal: true

# User and role administration is the security administrator's (LP-32).
class AdminUserPolicy < ApplicationPolicy
  def index?
    user&.security_admin?
  end

  def update_roles?
    user&.security_admin?
  end

  # Signing in as someone is holding everything they hold, so a security admin may only
  # become a standard user. Otherwise they could step around the separation by becoming
  # a system admin.
  def impersonate?
    return false unless user&.security_admin? && record != user

    user.owner? || record.standard_user?
  end
end
