# TEMPORARY — manual smoke test for Rails error telemetry. Delete after use.
# Inherits ActionController::Base, not ApplicationController, so no auth filter
# redirects before we get a chance to raise.
class TelemetryBoomController < ActionController::Base
  def show
    raise "Telemetry smoke test: deliberate crash"
  end
end
