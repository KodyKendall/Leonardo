class BoqsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_boq, only: [:show, :parse]

  def index
    @boqs = Boq.order(created_at: :desc)
  end

  def show
    @boq_items = @boq.boq_items.order(:sequence_order)
  end

  def new
    @boq = Boq.new
  end

  def create
    # Check if file is present first
    unless params[:boq][:csv_file].present?
      @boq = Boq.new
      @boq.errors.add(:csv_file, "can't be blank")
      render :new, status: :unprocessable_entity
      return
    end

    file = params[:boq][:csv_file]
    
    # Validate CSV extension
    unless file.original_filename.ends_with?('.csv')
      @boq = Boq.new
      @boq.errors.add(:csv_file, "must be a CSV file")
      render :new, status: :unprocessable_entity
      return
    end

    # Build BOQ with permitted params (excluding csv_file)
    @boq = Boq.new(boq_params)
    @boq.uploaded_by = current_user
    @boq.file_name = file.original_filename
    @boq.file_path = file.tempfile.path
    @boq.status = "uploaded"

    if @boq.save
      redirect_to @boq, notice: "BOQ uploaded successfully. Ready to parse."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def parse
    # Stub: Trigger LLM parsing process
    @boq.update(status: "parsing")
    
    # In a real implementation, this would call your LLM service
    # For now, just redirect back with a message
    redirect_to @boq, notice: "BOQ parsing initiated. This will be processed by the AI service."
  end

  private

  def set_boq
    @boq = Boq.find(params[:id])
  end

  def boq_params
    params.require(:boq).permit(:boq_name, :client_name, :client_reference, :qs_name, :received_date, :notes)
  end
end
