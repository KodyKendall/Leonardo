class VariationOrder < ApplicationRecord
  belongs_to :project
  belongs_to :created_by, class_name: 'User'
  belongs_to :approved_by, class_name: 'User', optional: true
end
