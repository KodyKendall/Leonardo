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
        # Recalculate totals when establishment_cost changes
        @tender_equipment_summary.calculate!
        
        format.html { redirect_to @tender_equipment_summary, notice: "Tender equipment summary was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tender_equipment_summary }
        format.turbo_stream do
          # Broadcast updates to both the establishment cost row and the summary card
          render turbo_stream: [
            turbo_stream.update("establishment_cost_row", partial: "equipment_selections/establishment_cost_row", locals: { tender_equipment_summary: @tender_equipment_summary }),
            turbo_stream.update("equipment_cost_summary", partial: "tender_equipment_summaries/summary", locals: { tender_equipment_summary: @tender_equipment_summary })
          ]
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender_equipment_summary.errors, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
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
      params.require(:tender_equipment_summary).permit(:tenant_id, :equipment_subtotal, :mobilization_fee, :establishment_cost, :total_equipment_cost, :rate_per_tonne_raw, :rate_per_tonne_rounded)
    end
end
