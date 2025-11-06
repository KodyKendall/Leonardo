json.extract! budget_allowance, :id, :project_id, :budget_category_id, :budgeted_amount, :actual_spend, :variance, :created_at, :updated_at
json.url budget_allowance_url(budget_allowance, format: :json)
