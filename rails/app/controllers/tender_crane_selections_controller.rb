class TenderCraneSelectionsController < ApplicationController
  before_action :set_tender_crane_selection, only: %i[ show edit update destroy ]

  # GET /tender_crane_selections or /tender_crane_selections.json
  def index
    @tender_crane_selections = TenderCraneSelection.all
  end

  # GET /tender_crane_selections/1 or /tender_crane_selections/1.json
  def show
    respond_to do |format|
      format.html
      format.turbo_stream { render inline: "<%= render 'tender_crane_selection', tender_crane_selection: @tender_crane_selection %>" }
    end
  end

  # GET /tender_crane_selections/new
  def new
    @tender_crane_selection = TenderCraneSelection.new
  end

  # GET /tender_crane_selections/1/edit
  def edit
  end

  # POST /tender_crane_selections or /tender_crane_selections.json
  def create
    @tender_crane_selection = TenderCraneSelection.new(tender_crane_selection_params)

    respond_to do |format|
      if @tender_crane_selection.save
        format.html { redirect_to @tender_crane_selection, notice: "Tender crane selection was successfully created." }
        format.json { render :show, status: :created, location: @tender_crane_selection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tender_crane_selection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tender_crane_selections/1 or /tender_crane_selections/1.json
  def update
    respond_to do |format|
      if @tender_crane_selection.update(tender_crane_selection_params)
        format.html { redirect_to @tender_crane_selection, notice: "Tender crane selection was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tender_crane_selection }
        format.turbo_stream { render :update }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender_crane_selection.errors, status: :unprocessable_entity }
        format.turbo_stream { render :update, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tender_crane_selections/1 or /tender_crane_selections/1.json
  def destroy
    @tender_crane_selection.destroy!

    respond_to do |format|
      format.html { redirect_to tender_crane_selections_path, notice: "Tender crane selection was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tender_crane_selection
      @tender_crane_selection = TenderCraneSelection.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tender_crane_selection_params
      params.require(:tender_crane_selection).permit(:tender_id, :crane_rate_id, :purpose, :quantity, :duration_days, :wet_rate_per_day, :total_cost, :sort_order)
    end
end
