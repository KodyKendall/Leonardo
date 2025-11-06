class BudgetAllowancesController < ApplicationController
  before_action :set_budget_allowance, only: %i[ show edit update destroy ]

  # GET /budget_allowances or /budget_allowances.json
  def index
    @budget_allowances = BudgetAllowance.all
  end

  # GET /budget_allowances/1 or /budget_allowances/1.json
  def show
  end

  # GET /budget_allowances/new
  def new
    @budget_allowance = BudgetAllowance.new
  end

  # GET /budget_allowances/1/edit
  def edit
  end

  # POST /budget_allowances or /budget_allowances.json
  def create
    @budget_allowance = BudgetAllowance.new(budget_allowance_params)

    respond_to do |format|
      if @budget_allowance.save
        format.html { redirect_to @budget_allowance, notice: "Budget allowance was successfully created." }
        format.json { render :show, status: :created, location: @budget_allowance }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @budget_allowance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /budget_allowances/1 or /budget_allowances/1.json
  def update
    respond_to do |format|
      if @budget_allowance.update(budget_allowance_params)
        format.html { redirect_to @budget_allowance, notice: "Budget allowance was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @budget_allowance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @budget_allowance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /budget_allowances/1 or /budget_allowances/1.json
  def destroy
    @budget_allowance.destroy!

    respond_to do |format|
      format.html { redirect_to budget_allowances_path, notice: "Budget allowance was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_budget_allowance
      @budget_allowance = BudgetAllowance.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def budget_allowance_params
      params.require(:budget_allowance).permit(:project_id, :budget_category_id, :budgeted_amount, :actual_spend, :variance)
    end
end
