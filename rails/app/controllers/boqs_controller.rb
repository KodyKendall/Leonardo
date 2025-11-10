class BoqsController < ApplicationController
  include LlamaBotRails::ControllerExtensions
  include LlamaBotRails::AgentAuth
  skip_before_action :verify_authenticity_token, only: [:update_attributes, :create_line_items]
  before_action :authenticate_user!
  before_action :set_boq, only: [:show, :parse, :update_attributes, :create_line_items, :chat]
  
  # Whitelist actions for LangGraph agent access
  llama_bot_allow :update_attributes, :create_line_items, :chat

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
    @boq.file_path = "active_storage"  # Placeholder for Active Storage
    @boq.status = "uploaded"
    @boq.csv_file.attach(file)

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

  def csv_download
    if File.exist?(@boq.file_path)
      send_file @boq.file_path, filename: @boq.file_name, type: "text/csv", disposition: "attachment"
    else
      redirect_to @boq, alert: "CSV file not found"
    end
  end

  def update_attributes
    # API endpoint for agent to update BOQ metadata
    respond_to do |format|
      if @boq.update(boq_update_params)
        @boq.update(parsed_at: Time.current, status: "parsed")
        format.json { render json: @boq, status: :ok }
      else
        format.json { render json: @boq.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_line_items
    # API endpoint for agent to create BOQ line items
    line_items_data = params.require(:line_items)
    created_items = []

    respond_to do |format|
      begin
        ActiveRecord::Base.transaction do
          line_items_data.each_with_index do |item_data, index|
            line_item = @boq.boq_items.new(
              item_number: item_data[:item_number],
              item_description: item_data[:item_description],
              unit_of_measure: item_data[:unit_of_measure],
              quantity: item_data[:quantity] || 0.0,
              section_category: item_data[:section_category],
              sequence_order: index + 1,
              notes: item_data[:notes]
            )
            line_item.save!
            created_items << line_item
          end
        end
        format.json { render json: { success: true, line_items: created_items, count: created_items.count }, status: :created }
      rescue StandardError => e
        format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  def chat
    # Endpoint to route chat messages to LangGraph boq_parser agent
    message = params[:message]
    raw_params = params[:raw_params] || {}

    respond_to do |format|
      begin
        # Create payload for LlamaBotRails chat channel
        chat_payload = {
          message: message,
          thread_id: "boq_#{@boq.id}_session",
          raw_params: raw_params.merge(boq_id: @boq.id),
          agent_state_builder_class: "BoqParserAgentStateBuilder"
        }

        # Call LlamaBotRails service to process message through agent
        response = LlamaBotRails::AgentService.new(
          user: current_user,
          agent_name: "boq_parser",
          message: message,
          thread_id: chat_payload[:thread_id],
          raw_params: chat_payload[:raw_params],
          state_builder_class: "BoqParserAgentStateBuilder"
        ).call

        format.json { render json: response, status: :ok }
      rescue StandardError => e
        Rails.logger.error("BOQ Chat Error: #{e.message}\n#{e.backtrace.join("\n")}")
        format.json { render json: { 
          message: "Error processing your request", 
          error: e.message 
        }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_boq
    @boq = Boq.find(params[:id])
  end

  def boq_params
    params.require(:boq).permit(:boq_name, :client_name, :client_reference, :qs_name, :received_date, :notes)
  end

  def boq_update_params
    params.require(:boq).permit(:boq_name, :client_name, :client_reference, :qs_name, :received_date, :notes)
  end
end
