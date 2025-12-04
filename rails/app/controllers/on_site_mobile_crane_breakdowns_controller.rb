class OnSiteMobileCraneBreakdownsController < ApplicationController
  before_action :set_on_site_mobile_crane_breakdown, only: %i[ show edit update destroy ]

  # GET /on_site_mobile_crane_breakdowns or /on_site_mobile_crane_breakdowns.json
  def index
    @on_site_mobile_crane_breakdowns = OnSiteMobileCraneBreakdown.all
  end

  # GET /on_site_mobile_crane_breakdowns/1 or /on_site_mobile_crane_breakdowns/1.json
  def show
  end

  # GET /on_site_mobile_crane_breakdowns/new
  def new
    @on_site_mobile_crane_breakdown = OnSiteMobileCraneBreakdown.new
  end

  # GET /on_site_mobile_crane_breakdowns/1/edit
  def edit
  end

  # POST /on_site_mobile_crane_breakdowns or /on_site_mobile_crane_breakdowns.json
  def create
    @on_site_mobile_crane_breakdown = OnSiteMobileCraneBreakdown.new(on_site_mobile_crane_breakdown_params)

    respond_to do |format|
      if @on_site_mobile_crane_breakdown.save
        format.html { redirect_to @on_site_mobile_crane_breakdown, notice: "On site mobile crane breakdown was successfully created." }
        format.json { render :show, status: :created, location: @on_site_mobile_crane_breakdown }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @on_site_mobile_crane_breakdown.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /on_site_mobile_crane_breakdowns/1 or /on_site_mobile_crane_breakdowns/1.json
  def update
    respond_to do |format|
      if @on_site_mobile_crane_breakdown.update(on_site_mobile_crane_breakdown_params)
        format.html { redirect_to @on_site_mobile_crane_breakdown, notice: "On site mobile crane breakdown was successfully updated.", status: :see_other }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@on_site_mobile_crane_breakdown, partial: "on_site_mobile_crane_breakdown", locals: { on_site_mobile_crane_breakdown: @on_site_mobile_crane_breakdown }) }
        format.json { render :show, status: :ok, location: @on_site_mobile_crane_breakdown }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@on_site_mobile_crane_breakdown, partial: "on_site_mobile_crane_breakdown", locals: { on_site_mobile_crane_breakdown: @on_site_mobile_crane_breakdown }) }
        format.json { render json: @on_site_mobile_crane_breakdown.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /on_site_mobile_crane_breakdowns/1 or /on_site_mobile_crane_breakdowns/1.json
  def destroy
    @on_site_mobile_crane_breakdown.destroy!

    respond_to do |format|
      format.html { redirect_to on_site_mobile_crane_breakdowns_path, notice: "On site mobile crane breakdown was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_on_site_mobile_crane_breakdown
      @on_site_mobile_crane_breakdown = OnSiteMobileCraneBreakdown.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def on_site_mobile_crane_breakdown_params
      params.require(:on_site_mobile_crane_breakdown).permit(:tender_id, :total_roof_area_sqm, :erection_rate_sqm_per_day, :program_duration_days, :ownership_type, :splicing_crane_required, :splicing_crane_size, :splicing_crane_days, :misc_crane_required, :misc_crane_size, :misc_crane_days)
    end
end
