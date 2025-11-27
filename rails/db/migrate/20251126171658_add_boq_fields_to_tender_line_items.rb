class AddBoqFieldsToTenderLineItems < ActiveRecord::Migration[7.2]
  def change
    add_column :tender_line_items, :page_number, :text
    add_column :tender_line_items, :item_number, :string
    add_column :tender_line_items, :item_description, :text
    add_column :tender_line_items, :unit_of_measure, :string
    add_column :tender_line_items, :section_category, :enum, enum_type: :section_category_enum
    add_column :tender_line_items, :notes, :text
  end
end
