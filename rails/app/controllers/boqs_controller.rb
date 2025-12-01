class BoqsController < ApplicationController
  include LlamaBotRails::ControllerExtensions
  include LlamaBotRails::AgentAuth
  skip_before_action :verify_authenticity_token, only: [:update_attributes, :create_line_items]
  before_action :authenticate_user!
  before_action :set_boq, only: [:show, :parse, :update_attributes, :create_line_items, :chat, :csv_as_json, :update_header_row, :export_boq_csv]
  before_action :set_tender, only: [:attach_boq]
  
  # Whitelist actions for LangGraph agent access
  llama_bot_allow :show, :update_attributes, :create_line_items, :chat

  def index
    @boqs = Boq.order(created_at: :desc)
  end

  def show
    @boq_items = @boq.boq_items.order(:sequence_order)
    respond_to do |format|
      format.html
      format.json { render json: @boq.to_json(include: :boq_items) }
    end
  end

  def new
    @boq = Boq.new
  end

  def create
    # Determine if this is a nested create under a tender
    @tender = Tender.find(params[:tender_id]) if params[:tender_id].present?
    
    # Check if file is present first
    unless params[:boq][:csv_file].present?
      @boq = Boq.new
      @boq.errors.add(:csv_file, "can't be blank")
      
      if @tender
        render :new, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
      return
    end

    file = params[:boq][:csv_file]
    
    # Validate CSV extension
    unless file.original_filename.ends_with?('.csv')
      @boq = Boq.new
      @boq.errors.add(:csv_file, "must be a CSV file")
      
      if @tender
        render :new, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
      return
    end

    # Build BOQ with permitted params (excluding csv_file)
    @boq = Boq.new(boq_params)
    @boq.uploaded_by = current_user
    @boq.file_name = file.original_filename
    @boq.file_path = "active_storage"  # Placeholder for Active Storage
    @boq.status = "uploaded"
    @boq.tender = @tender if @tender
    @boq.csv_file.attach(file)

    if @boq.save
      if @tender
        redirect_to tender_path(@tender), notice: "BOQ uploaded successfully."
      else
        redirect_to @boq, notice: "BOQ uploaded successfully. Ready to parse."
      end
    else
      if @tender
        render :new, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
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

  def csv_as_json
    # API endpoint to fetch complete CSV data as JSON array
    require 'csv'
    respond_to do |format|
      if @boq.csv_file.attached?
        begin
          csv_content = @boq.csv_file.download.force_encoding('UTF-8')
          
          # Get header row index from params or use stored value
          header_row_idx = params[:header_row_index].to_i rescue (@boq.header_row_index || 0)
          
          # Parse CSV with proper quote handling
          all_rows = CSV.parse(csv_content)
          
          # Extract headers from specified row
          headers = all_rows[header_row_idx] || []
          
          # Convert all rows to JSON objects (starting after header row)
          json_array = []
          all_rows.each_with_index do |row, idx|
            next if idx <= header_row_idx
            next if row.compact.empty? # Skip if all cells are empty
            
            row_object = {}
            headers.each_with_index do |header, index|
              row_object[header] = row[index] || ''
            end
            
            json_array << row_object
          end
          
          format.json { render json: json_array, status: :ok }
        rescue StandardError => e
          format.json { render json: { error: "Failed to parse CSV: #{e.message}" }, status: :unprocessable_entity }
        end
      else
        format.json { render json: { error: "No CSV file attached" }, status: :not_found }
      end
    end
  end

  def update_header_row
    # AJAX endpoint to update header_row_index and return updated CSV preview
    require 'csv'
    respond_to do |format|
      header_row_idx = params[:header_row_index].to_i
      
      # Validate header row index
      if header_row_idx < 0
        format.json { render json: { error: "Header row index cannot be negative" }, status: :unprocessable_entity }
        return
      end
      
      if @boq.update(header_row_index: header_row_idx)
        # Generate updated CSV preview with new header row
        if @boq.csv_file.attached?
          csv_content = @boq.csv_file.download.force_encoding('UTF-8')
          
          # Parse CSV with proper quote handling
          all_rows = CSV.parse(csv_content)
          
          if header_row_idx >= all_rows.length
            format.json { render json: { error: "Header row index exceeds file length" }, status: :unprocessable_entity }
            return
          end
          
          # Extract headers from specified row
          headers = all_rows[header_row_idx] || []
          
          # Build preview (first 20 rows after header)
          preview_rows = []
          all_rows.each_with_index do |row, idx|
            next if idx < header_row_idx + 1 || preview_rows.length >= 20
            next if row.compact.empty? # Skip if all cells are empty
            
            preview_rows << { columns: row }
          end
          
          format.json { render json: { 
            success: true, 
            headers: headers, 
            preview_rows: preview_rows,
            total_rows: all_rows.count
          }, status: :ok }
        else
          format.json { render json: { error: "No CSV file attached" }, status: :not_found }
        end
      else
        format.json { render json: @boq.errors, status: :unprocessable_entity }
      end
    end
  end

  def export_boq_csv
    # Export BOQ and BOQ Items as CSV
    require 'csv'
    
    respond_to do |format|
      format.csv do
        csv_data = CSV.generate do |csv|
          # Header section with BOQ metadata
          csv << ["BOQ Export"]
          csv << ["BOQ Name", @boq.boq_name]
          csv << ["Client Name", @boq.client_name]
          csv << ["Client Reference", @boq.client_reference]
          csv << ["QS Name", @boq.qs_name]
          csv << ["Received Date", @boq.received_date&.to_formatted_s(:short)]
          csv << ["Status", @boq.status]
          csv << ["Uploaded By", @boq.uploaded_by&.name]
          csv << [] # Blank row for separation
          
          # BOQ Items data
          csv << ["Item #", "Item Number", "Description", "Category", "UOM", "Quantity", "Notes"]
          
          @boq.boq_items.order(:sequence_order).each_with_index do |item, idx|
            csv << [
              idx + 1,
              item.item_number,
              item.item_description,
              item.section_category,
              item.unit_of_measure,
              item.quantity,
              item.notes
            ]
          end
        end
        
        # Set filename with timestamp
        filename = "#{@boq.boq_name.parameterize}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv"
        send_data csv_data, filename: filename, type: "text/csv", disposition: "attachment"
      end
    end
  end

  def search
    # Search for BOQs by name, client, or QS
    query = params[:q].to_s.strip
    
    respond_to do |format|
      format.json do
        if query.length < 1
          render json: [], status: :ok
        else
          boqs = Boq.where(tender_id: nil)
            .where("boq_name ILIKE ? OR client_name ILIKE ? OR qs_name ILIKE ?", 
              "%#{query}%", "%#{query}%", "%#{query}%")
            .order(created_at: :desc)
            .limit(10)
            .select(:id, :boq_name, :client_name, :qs_name, :status)
          
          render json: boqs, status: :ok
        end
      end
    end
  end

  def attach_boq
    # Attach an existing BOQ to a tender
    boq_id = params[:boq_id]
    boq = Boq.find_by(id: boq_id)
    
    if boq.nil?
      render json: { success: false, message: "BOQ not found" }, status: :not_found
    elsif boq.tender_id.present?
      render json: { success: false, message: "BOQ is already attached to another tender" }, status: :unprocessable_entity
    elsif boq.update(tender_id: @tender.id)
      render json: { success: true, message: "BOQ attached successfully" }, status: :ok
    else
      render json: { success: false, message: "Failed to attach BOQ" }, status: :unprocessable_entity
    end
  end

  private

  def set_boq
    @boq = Boq.find(params[:id])
  end

  def set_tender
    @tender = Tender.find(params[:id])
  end

  def boq_params
    params.require(:boq).permit(:boq_name, :client_name, :client_reference, :qs_name, :received_date, :notes, :header_row_index)
  end

  def boq_update_params
    params.require(:boq).permit(:boq_name, :client_name, :client_reference, :qs_name, :received_date, :notes, :header_row_index)
  end
end
