class VariationOrder < ApplicationRecord
  belongs_to :project
  belongs_to :created_by
  belongs_to :approved_by
end
