class Contact < ApplicationRecord
  belongs_to :client

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :primary, -> { where(is_primary: true) }

  before_save :ensure_single_primary
  after_destroy :ensure_primary_exists

  private

  def ensure_single_primary
    if is_primary?
      client.contacts.where.not(id: id).update_all(is_primary: false)
    elsif client.contacts.where.not(id: id).primary.empty?
      # If no other primary exists, this one must be primary
      self.is_primary = true
    end
  end

  def ensure_primary_exists
    return if client.destroyed?
    if client.contacts.primary.empty?
      client.contacts.first&.update(is_primary: true)
    end
  end
end
