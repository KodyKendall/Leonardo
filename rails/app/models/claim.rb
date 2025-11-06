class Claim < ApplicationRecord
  belongs_to :project
  belongs_to :submitted_by, class_name: 'User'
  has_many :claim_line_items
end
