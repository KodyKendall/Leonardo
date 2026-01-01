class EquipmentSelectionsController < ApplicationController
  before_action :set_tender
  before_action :set_equipment_selection, only: %i[ update destroy ]

  # GET /tenders/:tender_id/equipment_selections
  def index
    @equipment_selections = @tender.tender_equipment_selections.ordered
    @new_equipment_selection = TenderEquipmentSelection.new(tender: @tender)
    @equipment_types = EquipmentType.active
    @tender_equipment_summary = @tender.tender_equipment_summary || @tender.create_tender_equipment_summary!
  end

  # POST /tenders/:tender_id/equipment_selections
  def create
    @equipment_selection = @tender.tender_equipment_selections.build(equipment_selection_params)
    @equipment_types = EquipmentType.active

    respond_to do |format|
      if @equipment_selection.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("equipment_selections_table", partial: "equipment_selections/equipment_selection", locals: { equipment_selection: @equipment_selection }),
            turbo_stream.update("equipment_form", partial: "equipment_selections/add_form", locals: { tender: @tender, new_equipment_selection: TenderEquipmentSelection.new(tender: @tender), equipment_types: @equipment_types })
          ]
        end
        format.html { redirect_to tender_equipment_selections_path(@tender), notice: "Equipment selection was successfully created." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("equipment_form", partial: "equipment_selections/add_form", locals: { tender: @tender, new_equipment_selection: @equipment_selection, equipment_types: @equipment_types })
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenders/:tender_id/equipment_selections/:id
  def update
    respond_to do |format|
      if @equipment_selection.update(equipment_selection_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@equipment_selection, partial: "equipment_selections/equipment_selection", locals: { equipment_selection: @equipment_selection })
        end
        format.html { redirect_to tender_equipment_selections_path(@tender), notice: "Equipment selection was successfully updated.", status: :see_other }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@equipment_selection, partial: "equipment_selections/equipment_selection", locals: { equipment_selection: @equipment_selection }), status: :unprocessable_entity
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenders/:tender_id/equipment_selections/:id
  def destroy
    @equipment_selection.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove(@equipment_selection)
      end
      format.html { redirect_to tender_equipment_selections_path(@tender), notice: "Equipment selection was successfully destroyed.", status: :see_other }
    end
  end

  private

  def set_tender
    @tender = Tender.find(params[:tender_id])
  end

  def set_equipment_selection
    @equipment_selection = @tender.tender_equipment_selections.find(params[:id])
  end

  def equipment_selection_params
    params.require(:tender_equipment_selection).permit(:equipment_type_id, :units_required, :period_months, :purpose, :monthly_cost_override, :establishment_cost, :de_establishment_cost)
  end
end
