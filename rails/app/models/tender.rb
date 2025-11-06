class Tender < ApplicationRecord
  belongs_to :awarded_project, class_name: 'Project', optional: true
end
