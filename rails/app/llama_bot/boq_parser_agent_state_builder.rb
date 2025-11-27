# frozen_string_literal: true

class BoqParserAgentStateBuilder
  def initialize(params:, context:)
    @params = params
    @context = context
  end

  def build
    raw_params = @params["raw_params"] || {}
    user_message = @params["message"] || ""
    
    # Extract BOQ from route context (from /boqs/:id show page)
    # The context includes route_params with the :id from the URL
    boq_id = @context[:route_params]&.dig(:id) || raw_params["boq_id"] || raw_params["id"]
    boq = Boq.find_by(id: boq_id) if boq_id

    # Load CSV content from multiple sources (in priority order):
    # 1. Check if user pasted CSV content between <CSV> and </CSV> tags in message
    # 2. Check if BOQ has an attached CSV file
    csv_content = extract_csv_from_message(user_message)
    
    if csv_content.nil? && boq&.csv_file&.attached?
      csv_content = boq.csv_file.download
    end

    {
      message: @params["message"],
      thread_id: @params["thread_id"],
      api_token: @context[:api_token],
      agent_name: "boq_parser",  # Must match langgraph.json key
      boq_id: boq&.id,
      boq_name: boq&.boq_name,
      client_name: boq&.client_name,
      client_reference: boq&.client_reference,
      qs_name: boq&.qs_name,
      csv_content: csv_content,  # Raw CSV content for LLM to parse
      boq_metadata: {
        file_name: boq&.file_name,
        received_date: boq&.received_date,
        status: boq&.status,
        notes: boq&.notes
      }
    }
  end

  private

  def extract_csv_from_message(message)
    # Extract CSV content from <CSV>...</CSV> tags in user message
    return nil if message.blank?
    
    # Look for <CSV> ... </CSV> pattern (case-insensitive)
    match = message.match(/<CSV>(.*?)<\/CSV>/im)
    return match[1].strip if match
    
    # Alternative: Look for ```csv ... ``` markdown code blocks
    match = message.match(/```csv\n(.*?)\n```/im)
    return match[1].strip if match
    
    nil
  end
end
