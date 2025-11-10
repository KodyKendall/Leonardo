# frozen_string_literal: true

class BoqParserAgentStateBuilder
  def initialize(params:, context:)
    @params = params
    @context = context
  end

  def build
    raw_params = @params["raw_params"] || {}
    
    # Extract BOQ from context or params
    boq_id = raw_params["boq_id"]
    boq = Boq.find_by(id: boq_id) if boq_id

    # Load CSV content if BOQ has attached file
    csv_content = nil
    if boq&.csv_file&.attached?
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
end
