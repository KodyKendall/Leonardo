class Client < ApplicationRecord
  has_many :contacts, dependent: :destroy
  has_many :tenders, dependent: :nullify

  accepts_nested_attributes_for :contacts, allow_destroy: true, reject_if: :all_blank

  after_update :sync_name_to_tenders, if: :saved_change_to_business_name?

  def primary_contact
    contacts.find_by(is_primary: true) || contacts.first
  end

  private

  def sync_name_to_tenders
    tenders.update_all(client_name: business_name)
  end
end
