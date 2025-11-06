class FabricationRecordsController < ApplicationController
  before_action :set_fabrication_record, only: %i[ show edit update destroy ]

  # GET /fabrication_records or /fabrication_records.json
  def index
    @fabrication_records = FabricationRecord.all
  end

  # GET /fabrication_records/1 or /fabrication_records/1.json
  def show
  end

  # GET /fabrication_records/new
  def new
    @fabrication_record = FabricationRecord.new
  end

  # GET /fabrication_records/1/edit
  def edit
  end

  # POST /fabrication_records or /fabrication_records.json
  def create
    @fabrication_record = FabricationRecord.new(fabrication_record_params)

    respond_to do |format|
      if @fabrication_record.save
        format.html { redirect_to @fabrication_record, notice: "Fabrication record was successfully created." }
        format.json { render :show, status: :created, location: @fabrication_record }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fabrication_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fabrication_records/1 or /fabrication_records/1.json
  def update
    respond_to do |format|
      if @fabrication_record.update(fabrication_record_params)
        format.html { redirect_to @fabrication_record, notice: "Fabrication record was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @fabrication_record }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fabrication_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fabrication_records/1 or /fabrication_records/1.json
  def destroy
    @fabrication_record.destroy!

    respond_to do |format|
      format.html { redirect_to fabrication_records_path, notice: "Fabrication record was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fabrication_record
      @fabrication_record = FabricationRecord.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def fabrication_record_params
      params.require(:fabrication_record).permit(:project_id, :record_month, :tonnes_fabricated, :allowed_rate, :allowed_amount, :actual_spend)
    end
end
