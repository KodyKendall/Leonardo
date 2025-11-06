class Project < ApplicationRecord
  belongs_to :tender
  belongs_to :created_by
end
