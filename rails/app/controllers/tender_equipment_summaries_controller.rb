class TenderEquipmentSummariesController < ApplicationController
  before_action :set_tender_equipment_summary, only: %i[ show edit update destroy ]

  # GET /tender_equipment_summaries or /tender_equipment_summaries.json
  def index
    @tender_equipment_summaries = TenderEquipmentSummary.all
  end

  # GET /tender_equipment_summaries/1 or /tender_equipment_summaries/1.json
  def show
  end

  # GET /tender_equipment_summaries/new
  def new
    @tender_equipment_summary = TenderEquipmentSummary.new
  end

  # GET /tender_equipment_summaries/1/edit
  def edit
  end

  # POST /tender_equipment_summaries or /tender_equipment_summaries.json
  def create
    @tender_equipment_summary = TenderEquipmentSummary.new(tender_equipment_summary_params)

    respond_to do |format|
      if @tender_equipment_summary.save
        format.html { redirect_to @tender_equipment_summary, notice: "Tender equipment summary was successfully created." }
        format.json { render :show, status: :created, location: @tender_equipment_summary }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tender_equipment_summary.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tender_equipment_summaries/1 or /tender_equipment_summaries/1.json
  def update
    respond_to do |format|
      if @tender_equipment_summary.update(tender_equipment_summary_params)
        format.html { redirect_to @tender_equipment_summary, notice: "Tender equipment summary was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tender_equipment_summary }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender_equipment_summary.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tender_equipment_summaries/1 or /tender_equipment_summaries/1.json
  def destroy
    @tender_equipment_summary.destroy!

    respond_to do |format|
      format.html { redirect_to tender_equipment_summaries_path, notice: "Tender equipment summary was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tender_equipment_summary
      @tender_equipment_summary = TenderEquipmentSummary.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tender_equipment_summary_params
      params.require(:tender_equipment_summary).permit(:tender_id, :equipment_subtotal, :mobilization_fee, :total_equipment_cost, :rate_per_tonne_raw, :rate_per_tonne_rounded)
    end
end
