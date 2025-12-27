class TenderEquipmentSelectionsController < ApplicationController
  before_action :set_tender_equipment_selection, only: %i[ show edit update destroy ]

  # GET /tender_equipment_selections or /tender_equipment_selections.json
  def index
    @tender_equipment_selections = TenderEquipmentSelection.all
  end

  # GET /tender_equipment_selections/1 or /tender_equipment_selections/1.json
  def show
  end

  # GET /tender_equipment_selections/new
  def new
    @tender_equipment_selection = TenderEquipmentSelection.new
  end

  # GET /tender_equipment_selections/1/edit
  def edit
  end

  # POST /tender_equipment_selections or /tender_equipment_selections.json
  def create
    @tender_equipment_selection = TenderEquipmentSelection.new(tender_equipment_selection_params)

    respond_to do |format|
      if @tender_equipment_selection.save
        format.html { redirect_to @tender_equipment_selection, notice: "Tender equipment selection was successfully created." }
        format.json { render :show, status: :created, location: @tender_equipment_selection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tender_equipment_selection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tender_equipment_selections/1 or /tender_equipment_selections/1.json
  def update
    respond_to do |format|
      if @tender_equipment_selection.update(tender_equipment_selection_params)
        format.html { redirect_to @tender_equipment_selection, notice: "Tender equipment selection was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tender_equipment_selection }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender_equipment_selection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tender_equipment_selections/1 or /tender_equipment_selections/1.json
  def destroy
    @tender_equipment_selection.destroy!

    respond_to do |format|
      format.html { redirect_to tender_equipment_selections_path, notice: "Tender equipment selection was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tender_equipment_selection
      @tender_equipment_selection = TenderEquipmentSelection.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tender_equipment_selection_params
      params.require(:tender_equipment_selection).permit(:tender_id, :equipment_type_id, :units_required, :period_months, :purpose, :monthly_cost_override, :calculated_monthly_cost, :total_cost, :sort_order)
    end
end
