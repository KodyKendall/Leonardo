class MaterialSuppliesController < ApplicationController
  before_action :set_material_supply, only: %i[ show edit update destroy ]

  # GET /material_supplies or /material_supplies.json
  def index
    @material_supplies = MaterialSupply.all
  end

  # GET /material_supplies/1 or /material_supplies/1.json
  def show
  end

  # GET /material_supplies/new
  def new
    @material_supply = MaterialSupply.new
  end

  # GET /material_supplies/1/edit
  def edit
  end

  def reorder
    MaterialSupply.transaction do
      params[:ids].each_with_index do |id, index|
        MaterialSupply.find(id).update_column(:position, index + 1)
      end
    end
    head :ok
  end

  # POST /material_supplies or /material_supplies.json
  def create
    @material_supply = MaterialSupply.new(material_supply_params)

    respond_to do |format|
      if @material_supply.save
        format.html { redirect_to @material_supply, notice: "Material supply was successfully created." }
        format.json { render :show, status: :created, location: @material_supply }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @material_supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /material_supplies/1 or /material_supplies/1.json
  def update
    respond_to do |format|
      if @material_supply.update(material_supply_params)
        format.html { redirect_to @material_supply, notice: "Material supply was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @material_supply }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @material_supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /material_supplies/1 or /material_supplies/1.json
  def destroy
    @material_supply.destroy!

    respond_to do |format|
      format.html { redirect_to material_supplies_path, notice: "Material supply was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material_supply
      @material_supply = MaterialSupply.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def material_supply_params
      params.require(:material_supply).permit(:name, :waste_percentage)
    end
end
