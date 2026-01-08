class CraneRatesController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_crane_rate, only: %i[ show edit update destroy ]

  # GET /crane_rates or /crane_rates.json
  def index
    @crane_rates = CraneRate.ordered_by_size
    authorize CraneRate
  end

  # GET /crane_rates/1 or /crane_rates/1.json
  def show
    authorize @crane_rate
  end

  # GET /crane_rates/new
  def new
    @crane_rate = CraneRate.new(ownership_type: nil)
    authorize @crane_rate
  end

  # GET /crane_rates/1/edit
  def edit
    authorize @crane_rate
    respond_to do |format|
      format.html { render :edit }
      format.turbo_stream { render :edit, locals: { inline: true } }
    end
  end

  # POST /crane_rates or /crane_rates.json
  def create
    @crane_rate = CraneRate.new(crane_rate_params)
    authorize @crane_rate

    respond_to do |format|
      if @crane_rate.save
        format.html { redirect_to @crane_rate, notice: "Crane rate was successfully created." }
        format.json { render :show, status: :created, location: @crane_rate }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @crane_rate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /crane_rates/1 or /crane_rates/1.json
  def update
    authorize @crane_rate
    respond_to do |format|
      if @crane_rate.update(crane_rate_params)
        format.html { redirect_to @crane_rate, notice: "Crane rate was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @crane_rate }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@crane_rate),
            partial: "crane_rates/crane_rate",
            locals: { crane_rate: @crane_rate }
          )
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @crane_rate.errors, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@crane_rate),
            partial: "crane_rates/crane_rate",
            locals: { crane_rate: @crane_rate }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /crane_rates/1 or /crane_rates/1.json
  def destroy
    authorize @crane_rate
    @crane_rate.destroy!

    respond_to do |format|
      format.html { redirect_to crane_rates_path, notice: "Crane rate was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_crane_rate
      @crane_rate = CraneRate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def crane_rate_params
      params.require(:crane_rate).permit(:size, :ownership_type, :dry_rate_per_day, :diesel_per_day, :is_active, :effective_from)
    end
end
