class Admin::UsersController < Admin::BaseController
  def impersonate
    user = User.find(params[:id])
    session[:admin_id] = current_user.id
    sign_in(user)
    redirect_to root_path, notice: "Now impersonating #{user.email}"
  end

  def index
    @users = if params[:q].present?
      User.where("email ILIKE ?", "%#{params[:q]}%")
    else
      User.all
    end
  end
end
