class TendersController < ApplicationController
  before_action :set_tender, only: %i[ show edit update destroy ]

  # GET /tenders or /tenders.json
  def index
    @tenders = Tender.all
    @tenders = @tenders.where(status: params[:status]) if params[:status].present?
  end

  # GET /tenders/1 or /tenders/1.json
  def show
  end

  # GET /tenders/new
  def new
    @tender = Tender.new
    @clients = Client.all
  end

  # GET /tenders/1/edit
  def edit
    @clients = Client.all
  end

  # POST /tenders or /tenders.json
  def create
    @tender = Tender.new(tender_params)

    respond_to do |format|
      if @tender.save
        format.html { redirect_to @tender, notice: "Tender was successfully created." }
        format.json { render :show, status: :created, location: @tender }
      else
        @clients = Client.all
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

  # POST /tenders/quick_create
  def quick_create
    @tender = Tender.new(status: 'Draft', tender_name: "New Tender")
    
    if @tender.save
      redirect_to @tender, notice: "Draft tender created. Complete the details below."
    else
      redirect_to tenders_path, alert: "Unable to create tender."
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
      params.require(:tender).permit(:tender_name, :status, :client_id, :submission_deadline, :tender_value, :project_type, :notes, :awarded_project_id, :qob_file)
    end
end
