class LineItemMaterialBreakdownsController < ApplicationController
  before_action :set_line_item_material_breakdown, only: %i[ show edit update destroy ]

  # GET /line_item_material_breakdowns or /line_item_material_breakdowns.json
  def index
    @line_item_material_breakdowns = LineItemMaterialBreakdown.all
  end

  # GET /line_item_material_breakdowns/1 or /line_item_material_breakdowns/1.json
  def show
  end

  # GET /line_item_material_breakdowns/new
  def new
    @line_item_material_breakdown = LineItemMaterialBreakdown.new
  end

  # GET /line_item_material_breakdowns/1/edit
  def edit
  end

  # POST /line_item_material_breakdowns or /line_item_material_breakdowns.json
  def create
    @line_item_material_breakdown = LineItemMaterialBreakdown.new(line_item_material_breakdown_params)

    respond_to do |format|
      if @line_item_material_breakdown.save
        format.html { redirect_to @line_item_material_breakdown, notice: "Line item material breakdown was successfully created." }
        format.json { render :show, status: :created, location: @line_item_material_breakdown }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @line_item_material_breakdown.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /line_item_material_breakdowns/1 or /line_item_material_breakdowns/1.json
  def update
    respond_to do |format|
      if @line_item_material_breakdown.update(line_item_material_breakdown_params)
        format.turbo_stream do
          flash.now[:notice] = "Material breakdown saved successfully."
          render turbo_stream: [
            turbo_stream.replace(
              dom_id(@line_item_material_breakdown),
              partial: 'line_item_material_breakdowns/show',
              locals: { line_item_material_breakdown: @line_item_material_breakdown }
            ),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
        format.html { redirect_to @line_item_material_breakdown, notice: "Line item material breakdown was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @line_item_material_breakdown }
      else
        format.turbo_stream do
          flash.now[:alert] = "Failed to save: #{@line_item_material_breakdown.errors.full_messages.join(', ')}"
          render turbo_stream: [
            turbo_stream.replace(
              dom_id(@line_item_material_breakdown),
              partial: 'line_item_material_breakdowns/show',
              locals: { line_item_material_breakdown: @line_item_material_breakdown }
            ),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @line_item_material_breakdown.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /line_item_material_breakdowns/1 or /line_item_material_breakdowns/1.json
  def destroy
    @line_item_material_breakdown.destroy!

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Material breakdown deleted successfully."
        render turbo_stream: [
          turbo_stream.remove(dom_id(@line_item_material_breakdown)),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html { redirect_to line_item_material_breakdowns_path, notice: "Line item material breakdown was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_line_item_material_breakdown
      @line_item_material_breakdown = LineItemMaterialBreakdown.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def line_item_material_breakdown_params
      params.require(:line_item_material_breakdown).permit(:tender_line_item_id)
    end
end
