class Tender < ApplicationRecord
  belongs_to :awarded_project, class_name: 'Project', optional: true
  belongs_to :client, optional: true
  has_many :boqs, dependent: :destroy
  has_many :tender_line_items, dependent: :destroy
  has_many :tender_crane_selections, dependent: :destroy
  has_many :tender_specific_material_rates, dependent: :destroy
  has_many :material_supplies, through: :tender_specific_material_rates
  has_one :tender_inclusions_exclusion, dependent: :destroy
  has_one :on_site_mobile_crane_breakdown, dependent: :destroy
  
  # File attachment for QOB (Quote of Business)
  has_one_attached :qob_file
  
  # Callbacks
  before_create :generate_e_number
  after_create :populate_material_rates
  
  # Validations
  validates :tender_name, presence: true
  validates :status, presence: true, inclusion: { in: %w(Draft In\ Progress Submitted Awarded Not\ Awarded) }
  validate :qob_file_content_type
  
  # Status enum-like constant
  STATUSES = ['Draft', 'In Progress', 'Submitted', 'Awarded', 'Not Awarded'].freeze
  
  # Project types enum-like constant
  PROJECT_TYPES = ['Commercial', 'Mining'].freeze
  
  # Recalculate grand total as sum of all line item totals and broadcast update
  def recalculate_grand_total!
    new_total = tender_line_items.sum { |item| (item.line_item_rate_build_up&.rounded_rate || 0) * item.quantity }
    update_column(:grand_total, new_total)
    broadcast_update_grand_total
  end

  private

  def populate_material_rates
    PopulateTenderMaterialRates.new(self).execute
  end

  def broadcast_update_grand_total
    broadcast_update_to(
      "tender_#{id}_builder",
      target: "tender_#{id}_grand_total",
      partial: "tenders/grand_total",
      locals: { tender: self }
    )
  end
  
  def generate_e_number
    return if e_number.present?
    
    # Generate E-Number format: E + Year + Sequential number (e.g., E2025001)
    year = Date.current.year
    last_tender = Tender.where("e_number LIKE ?", "E#{year}%").order(e_number: :desc).first
    
    if last_tender&.e_number
      # Extract the sequential number and increment it
      last_number = last_tender.e_number.gsub("E#{year}", "").to_i
      new_number = last_number + 1
    else
      new_number = 1
    end
    
    # Format with leading zeros (e.g., E2025001)
    self.e_number = "E#{year}#{new_number.to_s.rjust(3, '0')}"
  end
  
  def qob_file_content_type
    if qob_file.attached? && !qob_file.content_type.in?(%w(text/csv application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet))
      errors.add(:qob_file, "must be a CSV or Excel file (.csv, .xlsx)")
    end
  end
end
