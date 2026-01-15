class AnchorRatesController < ApplicationController
  before_action :set_anchor_rate, only: %i[ show edit update destroy ]

  # GET /anchor_rates or /anchor_rates.json
  def index
    @anchor_rates = AnchorRate.all
    @suppliers = Supplier.where(name: ['Hilti', 'IKA', 'Fischer']).sort_by { |s| ['Hilti', 'IKA', 'Fischer'].index(s.name) }
    @existing_rates = AnchorSupplierRate.all.index_by { |rate| [rate.anchor_rate_id, rate.supplier_id] }
  end

  def reorder
    AnchorRate.transaction do
      params[:ids].each_with_index do |id, index|
        AnchorRate.find(id).update_column(:position, index + 1)
      end
    end
    head :ok
  end

  # GET /anchor_rates/1 or /anchor_rates/1.json
  def show
  end

  # GET /anchor_rates/new
  def new
    @anchor_rate = AnchorRate.new
  end

  # GET /anchor_rates/1/edit
  def edit
  end

  # POST /anchor_rates or /anchor_rates.json
  def create
    @anchor_rate = AnchorRate.new(anchor_rate_params)

    respond_to do |format|
      if @anchor_rate.save
        format.html { redirect_to @anchor_rate, notice: "Anchor rate was successfully created." }
        format.json { render :show, status: :created, location: @anchor_rate }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @anchor_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /anchor_rates/1 or /anchor_rates/1.json
  def update
    respond_to do |format|
      if @anchor_rate.update(anchor_rate_params)
        format.html { redirect_to @anchor_rate, notice: "Anchor rate was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @anchor_rate }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @anchor_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /anchor_rates/1 or /anchor_rates/1.json
  def destroy
    @anchor_rate.destroy!

    respond_to do |format|
      format.html { redirect_to anchor_rates_path, notice: "Anchor rate was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_anchor_rate
      @anchor_rate = AnchorRate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def anchor_rate_params
      params.require(:anchor_rate).permit(:name, :waste_percentage, :material_cost)
    end
end
