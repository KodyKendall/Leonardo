class NutBoltWasherRatesController < ApplicationController
  before_action :set_nut_bolt_washer_rate, only: %i[ show edit update destroy ]

  # GET /nut_bolt_washer_rates or /nut_bolt_washer_rates.json
  def index
    @nut_bolt_washer_rates = NutBoltWasherRate.all
    authorize @nut_bolt_washer_rates
  end

  # GET /nut_bolt_washer_rates/1 or /nut_bolt_washer_rates/1.json
  def show
    authorize @nut_bolt_washer_rate
  end

  # GET /nut_bolt_washer_rates/new
  def new
    @nut_bolt_washer_rate = NutBoltWasherRate.new
    authorize @nut_bolt_washer_rate
  end

  # GET /nut_bolt_washer_rates/1/edit
  def edit
    authorize @nut_bolt_washer_rate
  end

  # POST /nut_bolt_washer_rates or /nut_bolt_washer_rates.json
  def create
    @nut_bolt_washer_rate = NutBoltWasherRate.new(nut_bolt_washer_rate_params)
    authorize @nut_bolt_washer_rate

    respond_to do |format|
      if @nut_bolt_washer_rate.save
        format.html { redirect_to @nut_bolt_washer_rate, notice: "Nut bolt washer rate was successfully created." }
        format.json { render :show, status: :created, location: @nut_bolt_washer_rate }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @nut_bolt_washer_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /nut_bolt_washer_rates/1 or /nut_bolt_washer_rates/1.json
  def update
    authorize @nut_bolt_washer_rate
    respond_to do |format|
      if @nut_bolt_washer_rate.update(nut_bolt_washer_rate_params)
        format.html { redirect_to @nut_bolt_washer_rate, notice: "Nut bolt washer rate was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @nut_bolt_washer_rate }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @nut_bolt_washer_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nut_bolt_washer_rates/1 or /nut_bolt_washer_rates/1.json
  def destroy
    authorize @nut_bolt_washer_rate
    @nut_bolt_washer_rate.destroy!

    respond_to do |format|
      format.html { redirect_to nut_bolt_washer_rates_path, notice: "Nut bolt washer rate was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nut_bolt_washer_rate
      @nut_bolt_washer_rate = NutBoltWasherRate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def nut_bolt_washer_rate_params
      params.require(:nut_bolt_washer_rate).permit(:name, :waste_percentage, :material_cost)
    end
end
