class TendersController < ApplicationController
  before_action :set_tender, only: %i[ show edit update destroy ]

  # GET /tenders or /tenders.json
  def index
    @tenders = Tender.all
  end

  # GET /tenders/1 or /tenders/1.json
  def show
  end

  # GET /tenders/new
  def new
    @tender = Tender.new
  end

  # GET /tenders/1/edit
  def edit
  end

  # POST /tenders or /tenders.json
  def create
    @tender = Tender.new(tender_params)

    respond_to do |format|
      if @tender.save
        format.html { redirect_to @tender, notice: "Tender was successfully created." }
        format.json { render :show, status: :created, location: @tender }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tender.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenders/1 or /tenders/1.json
  def update
    respond_to do |format|
      if @tender.update(tender_params)
        format.html { redirect_to @tender, notice: "Tender was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tender }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenders/1 or /tenders/1.json
  def destroy
    @tender.destroy!

    respond_to do |format|
      format.html { redirect_to tenders_path, notice: "Tender was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tender
      @tender = Tender.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tender_params
      params.require(:tender).permit(:e_number, :status, :client_name, :tender_value, :project_type, :notes, :awarded_project_id)
    end
end
