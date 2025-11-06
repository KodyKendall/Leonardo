class Claim < ApplicationRecord
  belongs_to :project
  belongs_to :submitted_by
end
