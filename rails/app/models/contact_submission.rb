class ContactSubmission < ApplicationRecord
  validates :company_name, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :title, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create_commit :notify_site_owner

  private

  def notify_site_owner
    LlamaMailer.contact_notification(self).deliver_later
  end
end
