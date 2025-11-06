json.extract! tender, :id, :e_number, :status, :client_name, :tender_value, :project_type, :notes, :awarded_project_id, :created_at, :updated_at
json.url tender_url(tender, format: :json)
