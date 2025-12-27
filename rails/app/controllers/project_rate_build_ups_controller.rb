class ProjectRateBuildUpsController < ApplicationController
  before_action :set_tender
  before_action :set_project_rate_build_up, only: %i[ show edit update ]

  # GET /tenders/:tender_id/project_rate_build_ups/:id
  def show
  end

  # GET /tenders/:tender_id/project_rate_build_ups/:id/edit
  def edit
  end

  # PATCH/PUT /tenders/:tender_id/project_rate_build_ups/:id
  def update
    respond_to do |format|
      if @project_rate_build_up.update(project_rate_build_up_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("toast_container", partial: "shared/toast", locals: { message: "Project rates saved successfully!", type: "success" }),
            turbo_stream.replace(
              @project_rate_build_up,
              partial: "project_rate_build_ups/project_rate_build_up",
              locals: { project_rate_build_up: @project_rate_build_up }
            )
          ]
        end
        format.html { redirect_to tender_path(@tender), notice: "Project rate buildups updated successfully." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_tender
    @tender = Tender.find(params[:tender_id])
  end

  def set_project_rate_build_up
    @project_rate_build_up = @tender.project_rate_buildup
  end

  def project_rate_build_up_params
    params.require(:project_rate_build_up).permit(:material_supply_rate, :fabrication_rate, :overheads_rate, :shop_priming_rate, :onsite_painting_rate, :delivery_rate, :bolts_rate, :erection_rate, :crainage_rate, :cherry_picker_rate, :galvanizing_rate)
  end
end
