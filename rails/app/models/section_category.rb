class SectionCategory < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true

  def self.seed_from_enums
    BoqItem.section_categories.each do |name, display_name|
      find_or_create_by!(name: name) do |sc|
        sc.display_name = display_name
      end
    end
  end
end
