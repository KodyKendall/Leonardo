class Admin::DashboardController < Admin::BaseController
  def index
    authorize :admin_dashboard, :show?, policy_class: AdminDashboardPolicy
    @user_count = User.count
  end
end
