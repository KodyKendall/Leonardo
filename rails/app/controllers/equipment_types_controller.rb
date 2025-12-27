class EquipmentTypesController < ApplicationController
  before_action :set_equipment_type, only: %i[ show edit update destroy ]

  # GET /equipment_types or /equipment_types.json
  def index
    @equipment_types = EquipmentType.all
  end

  # GET /equipment_types/1 or /equipment_types/1.json
  def show
  end

  # GET /equipment_types/new
  def new
    @equipment_type = EquipmentType.new
  end

  # GET /equipment_types/1/edit
  def edit
  end

  # POST /equipment_types or /equipment_types.json
  def create
    @equipment_type = EquipmentType.new(equipment_type_params)

    respond_to do |format|
      if @equipment_type.save
        format.html { redirect_to @equipment_type, notice: "Equipment type was successfully created." }
        format.json { render :show, status: :created, location: @equipment_type }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @equipment_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /equipment_types/1 or /equipment_types/1.json
  def update
    respond_to do |format|
      if @equipment_type.update(equipment_type_params)
        format.html { redirect_to @equipment_type, notice: "Equipment type was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @equipment_type }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @equipment_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /equipment_types/1 or /equipment_types/1.json
  def destroy
    @equipment_type.destroy!

    respond_to do |format|
      format.html { redirect_to equipment_types_path, notice: "Equipment type was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_equipment_type
      @equipment_type = EquipmentType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def equipment_type_params
      params.require(:equipment_type).permit(:category, :model, :working_height_m, :base_rate_monthly, :damage_waiver_pct, :diesel_allowance_monthly, :is_active)
    end
end
