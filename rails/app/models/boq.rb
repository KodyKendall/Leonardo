class Boq < ApplicationRecord
  belongs_to :uploaded_by, class_name: "User", foreign_key: :uploaded_by_id, optional: true
  has_many :boq_items, dependent: :destroy

  validates :boq_name, :file_name, presence: true
  validates :status, inclusion: { in: %w(uploaded parsing parsed error) }, allow_nil: false

  enum :status, { uploaded: "uploaded", parsing: "parsing", parsed: "parsed", error: "error" }
end
