class CraneComplementsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_crane_complement, only: %i[ show edit update destroy ]

  # GET /crane_complements or /crane_complements.json
  def index
    @crane_complements = CraneComplement.all
  end

  # GET /crane_complements/1 or /crane_complements/1.json
  def show
  end

  # GET /crane_complements/new
  def new
    @crane_complement = CraneComplement.new
  end

  # GET /crane_complements/1/edit
  def edit
  end

  # POST /crane_complements or /crane_complements.json
  def create
    @crane_complement = CraneComplement.new(crane_complement_params)

    respond_to do |format|
      if @crane_complement.save
        format.html { redirect_to @crane_complement, notice: "Crane complement was successfully created." }
        format.json { render :show, status: :created, location: @crane_complement }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @crane_complement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /crane_complements/1 or /crane_complements/1.json
  def update
    respond_to do |format|
      if @crane_complement.update(crane_complement_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@crane_complement),
            partial: "crane_complements/crane_complement",
            locals: { crane_complement: @crane_complement }
          )
        end
        format.html { redirect_to @crane_complement, notice: "Crane complement was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @crane_complement }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@crane_complement),
            partial: "crane_complements/crane_complement",
            locals: { crane_complement: @crane_complement }
          ), status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @crane_complement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crane_complements/1 or /crane_complements/1.json
  def destroy
    @crane_complement.destroy!

    respond_to do |format|
      format.html { redirect_to crane_complements_path, notice: "Crane complement was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_crane_complement
      @crane_complement = CraneComplement.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def crane_complement_params
      params.require(:crane_complement).permit(:area_min_sqm, :area_max_sqm, :crane_recommendation, :default_wet_rate_per_day)
    end
end
