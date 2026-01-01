class PreliminariesGeneralItemTemplatesController < ApplicationController
  before_action :set_preliminaries_general_item_template, only: %i[ show edit update destroy ]

  # GET /preliminaries_general_item_templates or /preliminaries_general_item_templates.json
  def index
    @preliminaries_general_item_templates = PreliminariesGeneralItemTemplate.all
  end

  # GET /preliminaries_general_item_templates/1 or /preliminaries_general_item_templates/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render json: @preliminaries_general_item_template }
    end
  end

  # GET /preliminaries_general_item_templates/new
  def new
    @preliminaries_general_item_template = PreliminariesGeneralItemTemplate.new
  end

  # GET /preliminaries_general_item_templates/1/edit
  def edit
  end

  # POST /preliminaries_general_item_templates or /preliminaries_general_item_templates.json
  def create
    @preliminaries_general_item_template = PreliminariesGeneralItemTemplate.new(preliminaries_general_item_template_params)

    respond_to do |format|
      if @preliminaries_general_item_template.save
        format.html { redirect_to @preliminaries_general_item_template, notice: "Preliminaries general item template was successfully created." }
        format.json { render :show, status: :created, location: @preliminaries_general_item_template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @preliminaries_general_item_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /preliminaries_general_item_templates/1 or /preliminaries_general_item_templates/1.json
  def update
    respond_to do |format|
      if @preliminaries_general_item_template.update(preliminaries_general_item_template_params)
        format.html { redirect_to @preliminaries_general_item_template, notice: "Preliminaries general item template was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @preliminaries_general_item_template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @preliminaries_general_item_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /preliminaries_general_item_templates/1 or /preliminaries_general_item_templates/1.json
  def destroy
    @preliminaries_general_item_template.destroy!

    respond_to do |format|
      format.html { redirect_to preliminaries_general_item_templates_path, notice: "Preliminaries general item template was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_preliminaries_general_item_template
      @preliminaries_general_item_template = PreliminariesGeneralItemTemplate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def preliminaries_general_item_template_params
      params.require(:preliminaries_general_item_template).permit(:category, :description, :quantity, :rate, :sort_order, :is_crane, :is_access_equipment)
    end
end
