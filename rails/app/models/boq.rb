class Boq < ApplicationRecord
  belongs_to :tender, optional: true
  belongs_to :uploaded_by, class_name: "User", foreign_key: :uploaded_by_id, optional: true
  has_many :boq_items, dependent: :destroy
  has_one_attached :csv_file

  validates :boq_name, presence: true
  validates :status, inclusion: { in: %w(uploaded parsing parsed error) }, allow_nil: false

  enum :status, { uploaded: "uploaded", parsing: "parsing", parsed: "parsed", error: "error" }

  after_save :update_tender_status_on_attach

  private

  def update_tender_status_on_attach
    # Auto-set tender status to "In Progress" when a BOQ is attached to it
    if tender.present? && tender.status != 'In Progress'
      tender.update(status: 'In Progress')
    end
  end
end
