class Tender < ApplicationRecord
  belongs_to :awarded_project, class_name: 'Project', optional: true
  
  # File attachment for QOB (Quote of Business)
  has_one_attached :qob_file
  
  # Validations
  validate :qob_file_content_type
  
  private
  
  def qob_file_content_type
    if qob_file.attached? && !qob_file.content_type.in?(%w(text/csv application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet))
      errors.add(:qob_file, "must be a CSV or Excel file (.csv, .xlsx)")
    end
  end
end
