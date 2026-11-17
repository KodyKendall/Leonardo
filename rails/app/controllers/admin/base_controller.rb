class Admin::BaseController < ApplicationController
  before_action :require_signed_in

  rescue_from Pundit::NotAuthorizedError, with: :refuse_access

  private

  def require_signed_in
    redirect_to root_path unless current_user
  end

  def refuse_access
    LlamaBotRails::ActivityEvent.record!(
      "access_denied", actor: current_user, source: "admin",
      human: true,
      metadata: { method: request.method, path: request.path }
    )
    # An administrator hit the wrong domain, so say so. A standard user just goes home.
    return redirect_to(root_path) if current_user.standard_user?

    render plain: "Forbidden", status: :forbidden
  end
end
