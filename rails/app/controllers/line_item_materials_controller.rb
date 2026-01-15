class LineItemMaterialsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_line_item_material, only: %i[ show edit update destroy ]

  # GET /line_item_materials or /line_item_materials.json
  def index
    @line_item_materials = LineItemMaterial.all
  end

  # GET /line_item_materials/1 or /line_item_materials/1.json
  def show
  end

  # GET /line_item_materials/new
  def new
    @line_item_material = LineItemMaterial.new
    @line_item_material.tender_line_item_id = params[:tender_line_item_id] if params[:tender_line_item_id].present?
    @line_item_material.line_item_material_breakdown_id = params[:line_item_material_breakdown_id] if params[:line_item_material_breakdown_id].present?
  end

  # GET /line_item_materials/1/edit
  def edit
  end

  # POST /line_item_materials or /line_item_materials.json
  def create
    @line_item_material = LineItemMaterial.new(line_item_material_params)
    @breakdown = @line_item_material.line_item_material_breakdown

    respond_to do |format|
      if @line_item_material.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "line_item_materials_container_#{@breakdown&.id}",
              partial: 'line_item_materials/line_item_material',
              locals: { line_item_material: @line_item_material }
            ),
            turbo_stream.remove("no_materials_message_#{@breakdown&.id}"),
            turbo_stream.update(
              "material_breakdown_totals_#{@breakdown&.id}",
              partial: 'line_item_material_breakdowns/totals_section',
              locals: { line_item_material_breakdown: @breakdown }
            )
          ]
        end
        format.html do
          redirect_path = @breakdown ?
            line_item_material_breakdown_path(@breakdown) :
            @line_item_material
          redirect_to redirect_path, notice: "Line item material was successfully created."
        end
        format.json { render :show, status: :created, location: @line_item_material }
      else
        format.turbo_stream do
          flash.now[:alert] = "Failed to create material: #{@line_item_material.errors.full_messages.join(', ')}"
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash")
        end
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @line_item_material.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /line_item_materials/1 or /line_item_materials/1.json
  def update
    @breakdown = @line_item_material.line_item_material_breakdown
    @tender_line_item = @breakdown&.tender_line_item
    respond_to do |format|
      if @line_item_material.update(line_item_material_params)
        format.turbo_stream do
          flash.now[:notice] = "Material saved successfully."
          # Update the individual material row, breakdown totals, and rate buildup.
          # We explicitly refresh the RateBuildUp frame here because its after_commit
          # broadcasts may be delayed by nested transaction timing. The breakdown totals
          # also update via callback, but we include it here for safety.
          streams = [
            turbo_stream.replace(
              "line_item_material_#{@line_item_material.id}",
              partial: 'line_item_materials/line_item_material',
              locals: { line_item_material: @line_item_material }
            ),
            turbo_stream.update("flash", partial: "shared/flash"),
            turbo_stream.update(
              "material_breakdown_totals_#{@breakdown&.id}",
              partial: 'line_item_material_breakdowns/totals_section',
              locals: { line_item_material_breakdown: @breakdown }
            )
          ]
          
          # Explicitly update the RateBuildUp frame to ensure it reflects material changes
          if @tender_line_item.present?
            rate_buildup = @tender_line_item.line_item_rate_build_up
            if rate_buildup.present?
              streams << turbo_stream.replace(
                dom_id(rate_buildup),
                partial: 'line_item_rate_build_ups/line_item_rate_build_up',
                locals: { line_item_rate_build_up: rate_buildup }
              )
            end
          end
          
          render turbo_stream: streams
        end
        format.html { redirect_to @line_item_material, notice: "Line item material was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @line_item_material }
      else
        format.turbo_stream do
          flash.now[:alert] = "Failed to save material: #{@line_item_material.errors.full_messages.join(', ')}"
          render turbo_stream: [
            turbo_stream.replace(
              "line_item_material_#{@line_item_material.id}",
              partial: 'line_item_materials/line_item_material',
              locals: { line_item_material: @line_item_material }
            ),
            turbo_stream.update("flash", partial: "shared/flash")
          ]
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @line_item_material.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /line_item_materials/1 or /line_item_materials/1.json
  def destroy
    @breakdown = @line_item_material.line_item_material_breakdown
    @line_item_material.destroy!

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Material deleted successfully."
        render turbo_stream: [
          turbo_stream.remove("line_item_material_#{@line_item_material.id}"),
          turbo_stream.update("flash", partial: "shared/flash"),
          turbo_stream.update(
            "material_breakdown_totals_#{@breakdown&.id}",
            partial: 'line_item_material_breakdowns/totals_section',
            locals: { line_item_material_breakdown: @breakdown }
          )
        ]
      end
      format.html { redirect_to line_item_materials_path, notice: "Line item material was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_line_item_material
      @line_item_material = LineItemMaterial.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def line_item_material_params
      params.require(:line_item_material).permit(:tender_line_item_id, :material_supply_id, :material_supply_type, :proportion_percentage, :line_item_material_breakdown_id, :waste_percentage, :rate, :quantity)
    end
end
