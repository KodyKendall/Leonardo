class TenderSpecificMaterialRatesController < ApplicationController
  before_action :set_tender
  before_action :set_tender_specific_material_rate, only: [:edit, :update, :destroy]

  # GET /tenders/:tender_id/tender_specific_material_rates
  def index
    @tender_specific_material_rates = @tender.tender_specific_material_rates.includes(:material_supply)
  end

  # GET /tenders/:tender_id/tender_specific_material_rates/new
  def new
    @tender_specific_material_rate = @tender.tender_specific_material_rates.build
    @available_materials = MaterialSupply.all
  end

  # POST /tenders/:tender_id/tender_specific_material_rates
  def create
    @tender_specific_material_rate = @tender.tender_specific_material_rates.build(tender_specific_material_rate_params)

    if @tender_specific_material_rate.save
      redirect_to tender_tender_specific_material_rates_path(@tender), notice: 'Material rate was successfully created.'
    else
      @available_materials = MaterialSupply.all
      render :new, status: :unprocessable_entity
    end
  end

  # GET /tenders/:tender_id/tender_specific_material_rates/:id/edit
  def edit
    @available_materials = MaterialSupply.all
  end

  # PATCH/PUT /tenders/:tender_id/tender_specific_material_rates/:id
  def update
    if @tender_specific_material_rate.update(tender_specific_material_rate_params)
      redirect_to tender_tender_specific_material_rates_path(@tender), notice: 'Material rate was successfully updated.'
    else
      @available_materials = MaterialSupply.all
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tenders/:tender_id/tender_specific_material_rates/:id
  def destroy
    @tender_specific_material_rate.destroy
    redirect_to tender_tender_specific_material_rates_path(@tender), notice: 'Material rate was successfully deleted.'
  end

  private

  def set_tender
    @tender = Tender.find(params[:tender_id])
  end

  def set_tender_specific_material_rate
    @tender_specific_material_rate = @tender.tender_specific_material_rates.find(params[:id])
  end

  def tender_specific_material_rate_params
    params.require(:tender_specific_material_rate).permit(:material_supply_id, :rate, :unit, :effective_from, :effective_to, :notes)
  end
end
