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
    authorize Boq
    @boqs = Boq.order(created_at: :desc)
  end

  def show
    authorize @boq
    @boq_items = @boq.boq_items.order(:sequence_order)
    respond_to do |format|
      format.html
      format.json { render json: @boq.to_json(include: :boq_items, methods: [:tender_id]) }
    end
  end

  def new
    authorize Boq
    @boq = Boq.new
  end

  def create
    authorize Boq
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
    # Sanitize boq_name to remove null bytes
    sanitized_params = boq_params.to_h
    sanitized_params[:boq_name] = sanitized_params[:boq_name]&.delete("\u0000") if sanitized_params[:boq_name]
    sanitized_params[:client_name] = sanitized_params[:client_name]&.delete("\u0000") if sanitized_params[:client_name]
    sanitized_params[:qs_name] = sanitized_params[:qs_name]&.delete("\u0000") if sanitized_params[:qs_name]
    sanitized_params[:notes] = sanitized_params[:notes]&.delete("\u0000") if sanitized_params[:notes]

    @boq = Boq.new(sanitized_params)
    @boq.uploaded_by = current_user
    @boq.file_name = file.original_filename
    @boq.file_path = "active_storage"  # Placeholder for Active Storage
    @boq.status = "uploaded"
    @boq.tender = @tender if @tender
    @boq.csv_file.attach(file)

    if @boq.save
      redirect_to @boq, notice: "BOQ uploaded successfully. Ready to parse."
    else
      if @tender
        render :new, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def parse
    authorize @boq
    # Stub: Trigger LLM parsing process
    @boq.update(status: "parsing")
    
    # In a real implementation, this would call your LLM service
    # For now, just redirect back with a message
    redirect_to @boq, notice: "BOQ parsing initiated. This will be processed by the AI service."
  end

  def csv_download
    authorize @boq
    if File.exist?(@boq.file_path)
      send_file @boq.file_path, filename: @boq.file_name, type: "text/csv", disposition: "attachment"
    else
      redirect_to @boq, alert: "CSV file not found"
    end
  end

  def update_attributes
    authorize @boq
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
    authorize @boq
    # API endpoint for agent to create BOQ line items
    respond_to do |format|
      begin
        unless params.has_key?(:line_items)
          raise ActionController::ParameterMissing.new(:line_items)
        end

        line_items_data = params[:line_items] || []
        created_items = []

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
      rescue ActionController::ParameterMissing => e
        format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
      rescue StandardError => e
        format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  def chat
    authorize @boq
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
    authorize @boq
    # API endpoint to fetch complete CSV data as JSON array
    # Uses SpreadsheetParser for robust encoding handling (UTF-8 BOM, Windows-1252, etc.)
    respond_to do |format|
      if @boq.csv_file.attached?
        begin
          # Get header row index from params or use stored value (0-indexed from frontend)
          header_row_idx = params[:header_row_index].to_i rescue (@boq.header_row_index || 0)

          # SpreadsheetParser uses 1-indexed rows, frontend sends 0-indexed
          header_row = header_row_idx + 1

          SpreadsheetParser.with_attachment(@boq.csv_file, extension: detect_file_extension) do |spreadsheet|
            headers = extract_headers_from_spreadsheet(spreadsheet, header_row)
            json_array = build_json_array_from_spreadsheet(spreadsheet, headers, header_row)
            format.json { render json: json_array, status: :ok }
          end
        rescue SpreadsheetParser::ParseError => e
          Rails.logger.error "[BOQ CSV Parse Error] BOQ ID: #{@boq.id}, File: #{@boq.file_name}, Error: #{e.message}"
          format.json { render json: { error: "Could not parse file: #{e.message}" }, status: :unprocessable_entity }
        rescue StandardError => e
          Rails.logger.error "[BOQ CSV Parse Error] BOQ ID: #{@boq.id}, Error: #{e.class.name} - #{e.message}"
          format.json { render json: { error: "Failed to parse file: #{e.message}" }, status: :unprocessable_entity }
        end
      else
        format.json { render json: { error: "No CSV file attached" }, status: :not_found }
      end
    end
  end

  def update_header_row
    authorize @boq
    # AJAX endpoint to update header_row_index and return updated CSV preview
    # Uses SpreadsheetParser for robust encoding handling
    header_row_idx = params[:header_row_index].to_i

    # Validate header row index
    if header_row_idx < 0
      respond_to do |format|
        format.json { render json: { error: "Header row index cannot be negative" }, status: :unprocessable_entity }
      end
      return
    end

    # Check if CSV file is attached
    unless @boq.csv_file.attached?
      respond_to do |format|
        format.json { render json: { error: "No CSV file attached" }, status: :not_found }
      end
      return
    end

    begin
      SpreadsheetParser.with_attachment(@boq.csv_file, extension: detect_file_extension) do |spreadsheet|
        total_rows = spreadsheet.last_row || 0

        # Validate header row index (convert to 1-indexed for comparison)
        if header_row_idx + 1 > total_rows
          respond_to do |format|
            format.json { render json: { error: "Header row index exceeds file length" }, status: :unprocessable_entity }
          end
          return
        end

        respond_to do |format|
          if @boq.update(header_row_index: header_row_idx)
            # SpreadsheetParser uses 1-indexed rows
            header_row = header_row_idx + 1

            # Extract headers from specified row
            headers = spreadsheet.row(header_row) || []

            # Build preview (first 20 rows after header)
            preview_rows = []
            data_start = header_row + 1
            data_end = [spreadsheet.last_row || 0, header_row + 20].min

            (data_start..data_end).each do |row_num|
              row = spreadsheet.row(row_num)
              next if row.nil? || row.compact.empty?

              preview_rows << { columns: row, row_index: row_num - 1 } # Convert back to 0-indexed
            end

            format.json { render json: {
              success: true,
              headers: headers,
              preview_rows: preview_rows,
              total_rows: total_rows
            }, status: :ok }
          else
            format.json { render json: @boq.errors, status: :unprocessable_entity }
          end
        end
      end
    rescue SpreadsheetParser::ParseError => e
      Rails.logger.error "[BOQ CSV Parse Error] BOQ ID: #{@boq.id}, File: #{@boq.file_name}, Error: #{e.message}"
      respond_to do |format|
        format.json { render json: { error: "Could not parse file: #{e.message}" }, status: :unprocessable_entity }
      end
    rescue StandardError => e
      Rails.logger.error "[BOQ CSV Parse Error] BOQ ID: #{@boq.id}, Error: #{e.class.name} - #{e.message}"
      respond_to do |format|
        format.json { render json: { error: "Failed to parse file: #{e.message}" }, status: :unprocessable_entity }
      end
    end
  end

  def export_boq_csv
    authorize @boq
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
    authorize Boq
    # Search for BOQs by name, client, or QS (showing all results)
    query = params[:q].to_s.strip
    
    respond_to do |format|
      format.json do
        boqs = Boq.includes(:tender).order(created_at: :desc)
        
        if query.length > 0
          boqs = boqs.where("boq_name ILIKE ? OR client_name ILIKE ? OR qs_name ILIKE ?", 
            "%#{query}%", "%#{query}%", "%#{query}%")
        end
        
        boqs = boqs.limit(50)  # Limit after filtering
        
        # Format response to include tender information
        boqs_data = boqs.map do |boq|
          {
            id: boq.id,
            boq_name: boq.boq_name,
            client_name: boq.client_name,
            qs_name: boq.qs_name,
            status: boq.status,
            tender_id: boq.tender_id,
            tender_name: boq.tender&.tender_name
          }
        end
        
        render json: boqs_data, status: :ok
      end
    end
  end

  def attach_boq
    authorize Boq
    # Attach an existing BOQ to a tender
    boq_id = params[:boq_id]
    boq = Boq.find_by(id: boq_id)
    
    if boq.nil?
      render json: { success: false, message: "BOQ not found" }, status: :not_found
    elsif boq.update(tender_id: @tender.id)
      render json: { success: true, message: "BOQ attached successfully" }, status: :ok
    else
      render json: { success: false, message: "Failed to attach BOQ" }, status: :unprocessable_entity
    end
  end

  def detach
    authorize Boq
    # Detach a BOQ from its current tender
    boq = Boq.find_by(id: params[:id])
    
    if boq.nil?
      render json: { success: false, message: "BOQ not found" }, status: :not_found
    elsif boq.update(tender_id: nil)
      render json: { success: true, message: "BOQ detached successfully" }, status: :ok
    else
      render json: { success: false, message: "Failed to detach BOQ" }, status: :unprocessable_entity
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

  # Detect file extension from ActiveStorage attachment
  def detect_file_extension
    return '.csv' unless @boq.csv_file.attached?

    filename = @boq.csv_file.filename.to_s
    File.extname(filename).downcase.presence || '.csv'
  end

  # Extract headers from spreadsheet at given row (1-indexed)
  def extract_headers_from_spreadsheet(spreadsheet, header_row)
    raw_headers = spreadsheet.row(header_row) || []
    raw_headers.map.with_index do |header, index|
      if header.nil? || header.to_s.strip.empty?
        "column_#{index + 1}"
      else
        header.to_s.strip.gsub(/[[:space:]]+/, ' ').gsub(/[\r\n]+/, ' ')
      end
    end
  end

  # Build JSON array from spreadsheet rows (skips empty rows, adds _sequence_order)
  def build_json_array_from_spreadsheet(spreadsheet, headers, header_row)
    json_array = []
    sequence_order = 0
    data_start = header_row + 1
    data_end = spreadsheet.last_row || 0

    (data_start..data_end).each do |row_num|
      row = spreadsheet.row(row_num)
      next if row.nil? || row.compact.empty?

      sequence_order += 1
      row_object = { '_sequence_order' => sequence_order }

      headers.each_with_index do |header, index|
        value = row[index]
        row_object[header] = normalize_cell_value(value)
      end

      json_array << row_object
    end

    json_array
  end

  # Normalize cell values for JSON output
  def normalize_cell_value(value)
    case value
    when nil
      ''
    when String
      value.strip
    when Float
      value == value.to_i ? value.to_i : value
    else
      value
    end
  end
end
