class Project < ApplicationRecord
  belongs_to :tender
  belongs_to :created_by, class_name: 'User'
  has_many :budget_allowances
  has_many :claims
  has_many :fabrication_records
  has_many :variation_orders
end
