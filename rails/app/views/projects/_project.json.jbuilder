json.extract! project, :id, :rsb_number, :tender_id, :project_status, :project_start_date, :project_end_date, :budget_total, :actual_spend, :created_by_id, :created_at, :updated_at
json.url project_url(project, format: :json)
