class SectionCategoryTemplatesController < ApplicationController
  before_action :set_section_category_template, only: %i[ show edit update destroy bulk_create_slots ]

  # GET /section_category_templates or /section_category_templates.json
  def index
    @section_category_templates = SectionCategoryTemplate.all
  end

  # GET /section_category_templates/1 or /section_category_templates/1.json
  def show
  end

  def bulk_create_slots
    4.times do |i|
      @section_category_template.line_item_material_templates.create!(
        proportion_percentage: 25.0,
        waste_percentage: 0.0,
        sort_order: i
      )
    end
    redirect_to @section_category_template, notice: "4 default material slots were successfully created."
  end

  # GET /section_category_templates/new
  def new
    @section_category_template = SectionCategoryTemplate.new
  end

  # GET /section_category_templates/1/edit
  def edit
  end

  # POST /section_category_templates or /section_category_templates.json
  def create
    @section_category_template = SectionCategoryTemplate.new(section_category_template_params)

    respond_to do |format|
      if @section_category_template.save
        format.html { redirect_to @section_category_template, notice: "Section category template was successfully created." }
        format.json { render :show, status: :created, location: @section_category_template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @section_category_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /section_category_templates/1 or /section_category_templates/1.json
  def update
    respond_to do |format|
      if @section_category_template.update(section_category_template_params)
        format.html { redirect_to @section_category_template, notice: "Section category template was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @section_category_template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @section_category_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /section_category_templates/1 or /section_category_templates/1.json
  def destroy
    @section_category_template.destroy!

    respond_to do |format|
      format.html { redirect_to section_category_templates_path, notice: "Section category template was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_section_category_template
      @section_category_template = SectionCategoryTemplate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def section_category_template_params
      params.require(:section_category_template).permit(:section_category_id)
    end
end
