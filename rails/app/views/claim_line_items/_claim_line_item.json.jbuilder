json.extract! claim_line_item, :id, :claim_id, :line_item_description, :tender_rate, :claimed_quantity, :claimed_amount, :cumulative_quantity, :is_new_item, :price_escalation, :created_at, :updated_at
json.url claim_line_item_url(claim_line_item, format: :json)
