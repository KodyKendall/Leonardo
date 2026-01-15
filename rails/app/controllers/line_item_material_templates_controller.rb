class LineItemMaterialTemplatesController < ApplicationController
  before_action :set_line_item_material_template, only: %i[ show edit update destroy ]

  # GET /line_item_material_templates or /line_item_material_templates.json
  def index
    @line_item_material_templates = LineItemMaterialTemplate.all
  end

  # GET /line_item_material_templates/1 or /line_item_material_templates/1.json
  def show
  end

  # GET /line_item_material_templates/new
  def new
    @line_item_material_template = LineItemMaterialTemplate.new
  end

  # GET /line_item_material_templates/1/edit
  def edit
  end

  # POST /line_item_material_templates or /line_item_material_templates.json
  def create
    @line_item_material_template = LineItemMaterialTemplate.new(line_item_material_template_params)

    respond_to do |format|
      if @line_item_material_template.save
        format.html { redirect_to @line_item_material_template, notice: "Line item material template was successfully created." }
        format.json { render :show, status: :created, location: @line_item_material_template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @line_item_material_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /line_item_material_templates/1 or /line_item_material_templates/1.json
  def update
    respond_to do |format|
      if @line_item_material_template.update(line_item_material_template_params)
        format.html { redirect_to @line_item_material_template, notice: "Line item material template was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @line_item_material_template }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @line_item_material_template.errors, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@line_item_material_template, partial: "line_item_material_templates/line_item_material_template", locals: { line_item_material_template: @line_item_material_template }) }
      end
    end
  end

  # DELETE /line_item_material_templates/1 or /line_item_material_templates/1.json
  def destroy
    section_category_template = @line_item_material_template.section_category_template
    @line_item_material_template.destroy!

    respond_to do |format|
      format.html { redirect_to section_category_template_path(section_category_template), notice: "Line item material template was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@line_item_material_template) }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_line_item_material_template
      @line_item_material_template = LineItemMaterialTemplate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def line_item_material_template_params
      params.require(:line_item_material_template).permit(:section_category_template_id, :material_supply_id, :material_supply_type, :proportion_percentage, :waste_percentage, :sort_order)
    end
end
