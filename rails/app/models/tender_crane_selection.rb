class TenderCraneSelection < ApplicationRecord
  belongs_to :tender
  belongs_to :crane_rate

  enum purpose: { splicing: 'splicing', main: 'main' }
end
