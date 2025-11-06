class BudgetCategoriesController < ApplicationController
  before_action :set_budget_category, only: %i[ show edit update destroy ]

  # GET /budget_categories or /budget_categories.json
  def index
    @budget_categories = BudgetCategory.all
  end

  # GET /budget_categories/1 or /budget_categories/1.json
  def show
  end

  # GET /budget_categories/new
  def new
    @budget_category = BudgetCategory.new
  end

  # GET /budget_categories/1/edit
  def edit
  end

  # POST /budget_categories or /budget_categories.json
  def create
    @budget_category = BudgetCategory.new(budget_category_params)

    respond_to do |format|
      if @budget_category.save
        format.html { redirect_to @budget_category, notice: "Budget category was successfully created." }
        format.json { render :show, status: :created, location: @budget_category }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @budget_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /budget_categories/1 or /budget_categories/1.json
  def update
    respond_to do |format|
      if @budget_category.update(budget_category_params)
        format.html { redirect_to @budget_category, notice: "Budget category was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @budget_category }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @budget_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /budget_categories/1 or /budget_categories/1.json
  def destroy
    @budget_category.destroy!

    respond_to do |format|
      format.html { redirect_to budget_categories_path, notice: "Budget category was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_budget_category
      @budget_category = BudgetCategory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def budget_category_params
      params.require(:budget_category).permit(:category_name, :cost_code, :description)
    end
end
