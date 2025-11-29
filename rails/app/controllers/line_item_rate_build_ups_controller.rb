class LineItemRateBuildUpsController < ApplicationController
  before_action :set_line_item_rate_build_up, only: %i[ show edit update destroy ]

  # GET /line_item_rate_build_ups or /line_item_rate_build_ups.json
  def index
    @line_item_rate_build_ups = LineItemRateBuildUp.all
  end

  # GET /line_item_rate_build_ups/1 or /line_item_rate_build_ups/1.json
  def show
  end

  # GET /line_item_rate_build_ups/new
  def new
    @line_item_rate_build_up = LineItemRateBuildUp.new
  end

  # GET /line_item_rate_build_ups/1/edit
  def edit
  end

  # POST /line_item_rate_build_ups or /line_item_rate_build_ups.json
  def create
    @line_item_rate_build_up = LineItemRateBuildUp.new(line_item_rate_build_up_params)

    respond_to do |format|
      if @line_item_rate_build_up.save
        format.html { redirect_to @line_item_rate_build_up, notice: "Line item rate build up was successfully created." }
        format.json { render :show, status: :created, location: @line_item_rate_build_up }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @line_item_rate_build_up.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /line_item_rate_build_ups/1 or /line_item_rate_build_ups/1.json
  def update
    respond_to do |format|
      if @line_item_rate_build_up.update(line_item_rate_build_up_params)
        format.html { redirect_to @line_item_rate_build_up, notice: "Line item rate build up was successfully updated.", status: :see_other }
        format.turbo_stream { render :update }
        format.json { render json: @line_item_rate_build_up, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @line_item_rate_build_up.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /line_item_rate_build_ups/1 or /line_item_rate_build_ups/1.json
  def destroy
    @line_item_rate_build_up.destroy!

    respond_to do |format|
      format.html { redirect_to line_item_rate_build_ups_path, notice: "Line item rate build up was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_line_item_rate_build_up
      @line_item_rate_build_up = LineItemRateBuildUp.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def line_item_rate_build_up_params
      params.require(:line_item_rate_build_up).permit(:tender_line_item_id, :material_supply_rate, :fabrication_rate, :fabrication_included, :overheads_rate, :overheads_included, :shop_priming_rate, :shop_priming_included, :onsite_painting_rate, :onsite_painting_included, :delivery_rate, :delivery_included, :bolts_rate, :bolts_included, :erection_rate, :erection_included, :crainage_rate, :crainage_included, :cherry_picker_rate, :cherry_picker_included, :galvanizing_rate, :galvanizing_included, :subtotal, :margin_amount, :total_before_rounding, :rounded_rate)
    end
end
