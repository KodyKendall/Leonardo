class TenderCraneSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :crane_rate
end
