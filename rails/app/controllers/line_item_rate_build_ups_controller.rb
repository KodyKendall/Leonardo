class LineItemRateBuildUpsController < ApplicationController
  include ActionView::RecordIdentifier

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
        format.turbo_stream do
          tender_line_item = @line_item_rate_build_up.tender_line_item
          material_breakdown = tender_line_item&.line_item_material_breakdown
          streams = [
            turbo_stream.replace(
              dom_id(@line_item_rate_build_up),
              partial: "line_item_rate_build_ups/line_item_rate_build_up",
              locals: { line_item_rate_build_up: @line_item_rate_build_up }
            )
          ]
          if material_breakdown
            streams << turbo_stream.replace(
              dom_id(material_breakdown),
              partial: "line_item_material_breakdowns/line_item_material_breakdown",
              locals: { line_item_material_breakdown: material_breakdown, show_success: true }
            )
          end
          # Also update the tender line item frame to refresh line total
          if tender_line_item
            streams << turbo_stream.replace(
              dom_id(tender_line_item),
              partial: "tender_line_items/tender_line_item",
              locals: { tender_line_item: tender_line_item, open_breakdown: true }
            )
          end
          render turbo_stream: streams
        end
        format.json { render json: @line_item_rate_build_up, status: :ok }
      else
        
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              dom_id(@line_item_rate_build_up),
              partial: "line_item_rate_build_ups/line_item_rate_build_up",
              locals: { line_item_rate_build_up: @line_item_rate_build_up }
            ),
            turbo_stream.append("errors", "<div class='alert alert-error'>Validation failed: #{@line_item_rate_build_up.errors.full_messages.join(', ')}</div>")
          ]
        end
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
      params.require(:line_item_rate_build_up).permit(
        :tender_line_item_id, :material_supply_rate, :material_supply_included, :fabrication_rate, 
        :fabrication_included, :overheads_rate, :overheads_included, :shop_priming_rate, 
        :shop_priming_included, :onsite_painting_rate, :onsite_painting_included, :delivery_rate, 
        :delivery_included, :bolts_rate, :bolts_included, :erection_rate, :erection_included, 
        :crainage_rate, :crainage_included, :cherry_picker_rate, :cherry_picker_included, 
        :galvanizing_rate, :galvanizing_included, :subtotal, :margin_percentage, :mass_calc, :total_before_rounding, 
        :rounded_rate, :rounding_interval,
        rate_buildup_custom_items_attributes: [:id, :description, :rate, :included, :sort_order, :_destroy]
      )
    end
end
