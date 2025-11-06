json.extract! claim, :id, :claim_number, :project_id, :claim_date, :claim_status, :total_claimed, :total_paid, :amount_due, :submitted_by_id, :notes, :created_at, :updated_at
json.url claim_url(claim, format: :json)
