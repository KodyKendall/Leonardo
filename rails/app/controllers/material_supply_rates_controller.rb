class MaterialSupplyRatesController < ApplicationController
  before_action :set_material_supply_rate, only: %i[ show edit update destroy ]

  # GET /material_supply_rates or /material_supply_rates.json
  def index
    @material_supply_rates = MaterialSupplyRate.all
  end

  # GET /material_supply_rates/1 or /material_supply_rates/1.json
  def show
  end

  # GET /material_supply_rates/new
  def new
    @material_supply_rate = MaterialSupplyRate.new
  end

  # GET /material_supply_rates/1/edit
  def edit
  end

  # POST /material_supply_rates or /material_supply_rates.json
  def create
    @material_supply_rate = MaterialSupplyRate.new(material_supply_rate_params)

    respond_to do |format|
      if @material_supply_rate.save
        # If it's an AJAX/FormData request, just return 200 OK
        format.html { redirect_to @material_supply_rate, notice: "Material supply rate was successfully created." }
        format.json { render :show, status: :created, location: @material_supply_rate }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @material_supply_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /material_supply_rates/1 or /material_supply_rates/1.json
  def update
    respond_to do |format|
      if @material_supply_rate.update(material_supply_rate_params)
        format.html { redirect_to @material_supply_rate, notice: "Material supply rate was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @material_supply_rate }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @material_supply_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /material_supply_rates/1 or /material_supply_rates/1.json
  def destroy
    @material_supply_rate.destroy!

    respond_to do |format|
      format.html { redirect_to material_supply_rates_path, notice: "Material supply rate was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_supply_rate
      @material_supply_rate = MaterialSupplyRate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def material_supply_rate_params
      params.require(:material_supply_rate).permit(:rate, :unit, :material_supply_id, :supplier_id, :monthly_material_supply_rate_id)
    end
end
