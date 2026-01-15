class SectionCategoriesController < ApplicationController
  before_action :set_section_category, only: %i[ show edit update destroy ]

  # GET /section_categories or /section_categories.json
  def index
    @section_categories = SectionCategory.all
    authorize SectionCategory
  end

  # GET /section_categories/1 or /section_categories/1.json
  def show
    authorize @section_category
  end

  # GET /section_categories/new
  def new
    @section_category = SectionCategory.new
    authorize @section_category
  end

  # GET /section_categories/1/edit
  def edit
    authorize @section_category
  end

  # POST /section_categories or /section_categories.json
  def create
    @section_category = SectionCategory.new(section_category_params)
    authorize @section_category

    respond_to do |format|
      if @section_category.save
        format.html { redirect_to @section_category, notice: "Section category was successfully created." }
        format.json { render :show, status: :created, location: @section_category }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @section_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /section_categories/1 or /section_categories/1.json
  def update
    authorize @section_category
    respond_to do |format|
      if @section_category.update(section_category_params)
        format.html { redirect_to @section_category, notice: "Section category was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @section_category }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @section_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /section_categories/1 or /section_categories/1.json
  def destroy
    authorize @section_category
    @section_category.destroy!

    respond_to do |format|
      format.html { redirect_to section_categories_path, notice: "Section category was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_section_category
      @section_category = SectionCategory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def section_category_params
      params.require(:section_category).permit(:name, :display_name, :supply_rates_type)
    end
end
