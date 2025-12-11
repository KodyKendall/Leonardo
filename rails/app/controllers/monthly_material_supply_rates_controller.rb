class MonthlyMaterialSupplyRatesController < ApplicationController
  before_action :set_monthly_material_supply_rate, only: %i[ show edit update destroy save_rate ]

  # GET /monthly_material_supply_rates or /monthly_material_supply_rates.json
  def index
    @monthly_material_supply_rates = MonthlyMaterialSupplyRate.all
  end

  # GET /monthly_material_supply_rates/1 or /monthly_material_supply_rates/1.json
  def show
    @material_supplies = MaterialSupply.all.order(:name)
    supplier_order = ["BSI", "MacSteel", "Steelrode", "S&L", "BBD", "Fast Flame"]
    @suppliers = Supplier.all.sort_by { |s| supplier_order.index(s.name) || supplier_order.length }
    @existing_rates = @monthly_material_supply_rate.material_supply_rates.index_by { |rate| [rate.material_supply_id, rate.supplier_id] }
  end

  # GET /monthly_material_supply_rates/new
  def new
    @monthly_material_supply_rate = MonthlyMaterialSupplyRate.new
  end

  # GET /monthly_material_supply_rates/1/edit
  def edit
  end

  # POST /monthly_material_supply_rates or /monthly_material_supply_rates.json
  def create
    @monthly_material_supply_rate = MonthlyMaterialSupplyRate.new(monthly_material_supply_rate_params)
    
    # Parse month string (e.g., "2025-12") from HTML5 month field to Date object
    if params[:monthly_material_supply_rate][:effective_from].present?
      month_string = params[:monthly_material_supply_rate][:effective_from]
      if month_string.match?(/\A\d{4}-\d{2}\z/)
        parsed_date = Date.strptime(month_string, "%Y-%m")
        @monthly_material_supply_rate.effective_from = parsed_date.beginning_of_month
        @monthly_material_supply_rate.effective_to = parsed_date.end_of_month
      end
    end

    respond_to do |format|
      if @monthly_material_supply_rate.save
        format.html { redirect_to @monthly_material_supply_rate, notice: "Monthly material supply rate was successfully created." }
        format.json { render :show, status: :created, location: @monthly_material_supply_rate }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @monthly_material_supply_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /monthly_material_supply_rates/1 or /monthly_material_supply_rates/1.json
  def update
    respond_to do |format|
      if @monthly_material_supply_rate.update(monthly_material_supply_rate_params)
        # Process bulk material supply rates if present
        if params[:material_supply_rates].present?
          process_bulk_material_rates
        end
        format.html { redirect_to @monthly_material_supply_rate, notice: "Material supply rates were successfully saved.", status: :see_other }
        format.json { render :show, status: :ok, location: @monthly_material_supply_rate }
      else
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @monthly_material_supply_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /monthly_material_supply_rates/1/save_rate
  def save_rate
    material_supply_rate = MaterialSupplyRate.find_or_initialize_by(
      material_supply_id: params[:material_supply_id],
      supplier_id: params[:supplier_id],
      monthly_material_supply_rate_id: @monthly_material_supply_rate.id
    )
    
    material_supply_rate.rate = params[:rate]
    material_supply_rate.unit = "tonne"
    
    if material_supply_rate.save
      render json: { success: true, id: material_supply_rate.id }
    else
      render json: { success: false, error: material_supply_rate.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # DELETE /monthly_material_supply_rates/1 or /monthly_material_supply_rates/1.json
  def destroy
    @monthly_material_supply_rate.destroy!

    respond_to do |format|
      format.html { redirect_to monthly_material_supply_rates_path, notice: "Monthly material supply rate was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def process_bulk_material_rates
      material_supply_rates_params = params.require(:material_supply_rates)
      
      material_supply_rates_params.each do |material_supply_id, suppliers_hash|
        suppliers_hash.each do |supplier_id, rate|
          next if rate.blank?
          
          material_supply_rate = MaterialSupplyRate.find_or_initialize_by(
            material_supply_id: material_supply_id,
            supplier_id: supplier_id,
            monthly_material_supply_rate_id: @monthly_material_supply_rate.id
          )
          
          material_supply_rate.rate = rate
          material_supply_rate.unit = "tonne"
          material_supply_rate.save
        end
      end
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_monthly_material_supply_rate
      @monthly_material_supply_rate = MonthlyMaterialSupplyRate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def monthly_material_supply_rate_params
      params.require(:monthly_material_supply_rate).permit(:effective_from, :effective_to)
    end
end
