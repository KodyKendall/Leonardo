class Admin::UsersController < Admin::BaseController
  def impersonate
    user = User.find(params[:id])
    authorize user, :impersonate?, policy_class: AdminUserPolicy
    LlamaBotRails::ActivityEvent.record!(
      "impersonation_started", subject: user, actor: current_user, source: "admin",
      human: true
    )
    session[:admin_id] = current_user.id
    sign_in(user)
    redirect_to root_path, notice: "Now impersonating #{user.email}"
  end

  def index
    authorize User, :index?, policy_class: AdminUserPolicy
    @users = if params[:q].present?
      User.where("email ILIKE ?", "%#{params[:q]}%")
    else
      User.all
    end
  end

  def update_roles
    user = User.find(params[:id])
    authorize user, :update_roles?, policy_class: AdminUserPolicy
    user.change_administrative_roles!(
      by: current_user,
      security: flag(:security_admin),
      system: flag(:system_admin),
      owner: flag(:owner),
      reason: params[:reason]
    )
    redirect_to admin_users_path, notice: "Roles updated for #{user.email}"
  rescue LlamaBotRails::AdministrativeRoles::NotPermitted => e
    LlamaBotRails::ActivityEvent.record!(
      "access_denied", subject: user, actor: current_user, source: "admin",
      human: true,
      metadata: { reason: e.message }
    )
    redirect_to admin_users_path, alert: e.message, status: :see_other
  end

  private

  # Absent means leave it alone, which is different from false.
  def flag(name)
    return nil unless params.key?(name)

    ActiveModel::Type::Boolean.new.cast(params[name])
  end
end
