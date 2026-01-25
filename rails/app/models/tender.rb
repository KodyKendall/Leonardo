class Tender < ApplicationRecord
  belongs_to :awarded_project, class_name: 'Project', optional: true
  belongs_to :client, optional: true
  belongs_to :contact, optional: true
  has_many :boqs, dependent: :destroy
  has_many :tender_line_items, -> { ordered }, dependent: :destroy
  has_many :tender_crane_selections, dependent: :destroy
  has_many :tender_specific_material_rates, dependent: :destroy
  has_many :material_supplies, through: :tender_specific_material_rates
  has_many :tender_equipment_selections, dependent: :destroy
  has_many :preliminaries_general_items, dependent: :destroy
  has_many :equipment_types, through: :tender_equipment_selections
  has_one :tender_inclusions_exclusion, dependent: :destroy
  has_one :on_site_mobile_crane_breakdown, dependent: :destroy
  has_one :tender_equipment_summary, dependent: :destroy
  has_one :project_rate_buildup, class_name: 'ProjectRateBuildUp', dependent: :destroy
  
  # File attachment for QOB (Quote of Business)
  has_one_attached :qob_file
  
  # Callbacks
  after_initialize :set_report_defaults, if: :new_record?
  before_save :sync_client_name, if: -> { client_id_changed? }
  before_save :set_default_contact, if: -> { client_id_changed? && contact_id.blank? }
  before_create :generate_e_number
  after_create :populate_material_rates
  after_create :create_project_rate_buildup
  
  # Validations
  validates :tender_name, presence: true
  validates :status, presence: true, inclusion: { in: %w(Draft In\ Progress Submitted Awarded Not\ Awarded) }
  validates :p_and_g_display_mode, presence: true, inclusion: { in: %w(detailed rolled_up) }
  validates :shop_drawings_display_mode, presence: true, inclusion: { in: %w(lump_sum tonnage_rate) }
  validate :qob_file_content_type
  
  # Status enum-like constant
  STATUSES = ['Draft', 'In Progress', 'Submitted', 'Awarded', 'Not Awarded'].freeze
  
  # Project types enum-like constant
  PROJECT_TYPES = ['Commercial', 'Mining'].freeze

  # Report display modes
  PG_DISPLAY_MODES = [['Detailed Breakdown', 'detailed'], ['Rolled-up Lump Sum', 'rolled_up']].freeze
  SHOP_DRAWINGS_DISPLAY_MODES = [['Lump Sum', 'lump_sum'], ['Tonnage & Rate', 'tonnage_rate']].freeze

  # Recalculate grand total as sum of all line item totals + shop drawings total + P&G items and broadcast update
  # Excludes heading rows (is_heading: true) from calculations
  def recalculate_grand_total!
    # Use SQL sum to avoid N+1 queries for line item rate build ups
    line_items_total = tender_line_items.where(is_heading: false).sum('quantity * rate')
    
    shop_drawings_total = project_rate_buildup&.shop_drawings_total || 0
    p_and_g_total = preliminaries_general_items.sum('quantity * rate')
    
    new_total = line_items_total + shop_drawings_total + p_and_g_total
    update_columns(grand_total: new_total, tender_value: new_total)
    broadcast_update_grand_total
    broadcast_update_rate_per_tonne
  end

  # Returns the client name with fallbacks
  def display_client_name
    return client_name if client_name.present?
    return client&.business_name if client&.business_name.present?
    return boqs.first&.client_name if boqs.first&.client_name.present?
    "(No client specified)"
  end

  # Returns both client name and contact person (if available)
  def display_client_and_contact
    contact_part = contact&.name ? " (#{contact.name})" : ""
    "#{display_client_name}#{contact_part}"
  end

  # Returns the expiration date: submission_deadline if set, otherwise 30 days from today
  def report_expiration_date
    submission_deadline || (Date.current + 30.days)
  end

  # Recalculate total tonnage as sum of all line item quantities where include_in_tonnage is true
  # Excludes heading rows (is_heading: true) from calculations
  # Also calculates financial_tonnage which includes ALL line items
  def recalculate_total_tonnage!(cascade: true)
    # Calculate both tonnages in a single query to improve performance
    # Use unscope(:order) to avoid PG::GroupingError when default scope includes ordering
    stats = tender_line_items.unscope(:order)
                             .where(is_heading: false)
                             .pick(
                               Arel.sql("SUM(CASE WHEN include_in_tonnage = true THEN quantity ELSE 0 END)"),
                               Arel.sql("SUM(quantity)")
                             )
    
    new_tonnage = (stats[0] || 0).to_f
    new_financial_tonnage = (stats[1] || 0).to_f
    
    self.total_tonnage = new_tonnage
    self.financial_tonnage = new_financial_tonnage
    
    update_columns(total_tonnage: new_tonnage, financial_tonnage: new_financial_tonnage)
    
    broadcast_update_total_tonnage
    broadcast_update_rate_per_tonne
    
    if cascade
      # Also recalculate equipment summary since cost per tonne depends on total_tonnage
      recalculate_equipment_summary!
      # Recalculate project rate buildup since crainage rate depends on total_tonnage
      recalculate_project_rate_buildup!
      # Recalculate crane breakdown to trigger P&G sync
      recalculate_crane_breakdown!
    end
  end

  def rate_per_tonne
    return 0 if total_tonnage.to_f == 0
    grand_total.to_f / total_tonnage.to_f
  end

  # Recalculate crane breakdown to trigger P&G sync
  def recalculate_crane_breakdown!
    on_site_mobile_crane_breakdown&.touch
  end

  # Recalculate project rate buildup when tender tonnage changes
  def recalculate_project_rate_buildup!
    project_rate_buildup&.save!
  end

  # Recalculate equipment summary when tender tonnage changes
  def recalculate_equipment_summary!
    summary = tender_equipment_summary
    if summary.present?
      summary.calculate!
      # Broadcast the update to the equipment selections page
      summary.broadcast_update
    end
  end

  private

  def set_report_defaults
    self.p_and_g_display_mode ||= 'detailed'
    self.shop_drawings_display_mode ||= 'lump_sum'
  end

  def sync_client_name
    self.client_name = client&.business_name
  end

  def set_default_contact
    return unless client.present?
    # Set to the client's primary contact if available
    self.contact = client.primary_contact
  end

  def populate_material_rates
    PopulateTenderMaterialRates.new(self).execute
  end

  def create_project_rate_buildup
    ProjectRateBuildUp.create!(tender: self)
  end

  def broadcast_update_grand_total
    broadcast_update_to(
      "tender_#{id}_builder",
      target: "tender_#{id}_grand_total",
      partial: "tenders/grand_total",
      locals: { tender: self }
    )
  end

  def broadcast_update_total_tonnage
    broadcast_update_to(
      "tender_#{id}_builder",
      target: "tender_#{id}_total_tonnes",
      partial: "tenders/total_tonnes",
      locals: { tender: self }
    )
  end

  def broadcast_update_rate_per_tonne
    broadcast_update_to(
      "tender_#{id}_builder",
      target: "tender_#{id}_rate_per_tonne",
      partial: "tenders/rate_per_tonne",
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
