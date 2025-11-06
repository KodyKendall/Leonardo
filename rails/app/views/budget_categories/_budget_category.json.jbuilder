json.extract! budget_category, :id, :category_name, :cost_code, :description, :created_at, :updated_at
json.url budget_category_url(budget_category, format: :json)
