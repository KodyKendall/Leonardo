class BudgetAllowance < ApplicationRecord
  belongs_to :project
  belongs_to :budget_category
end
