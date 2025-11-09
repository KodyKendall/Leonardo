class BoqItem < ApplicationRecord
  belongs_to :boq

  validates :boq_id, presence: true
end
