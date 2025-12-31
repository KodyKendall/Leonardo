class Client < ApplicationRecord
  has_many :tenders, dependent: :nullify

  after_update :sync_name_to_tenders, if: :saved_change_to_business_name?

  private

  def sync_name_to_tenders
    tenders.update_all(client_name: business_name)
  end
end
