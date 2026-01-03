class AddPositionToTenderLineItems < ActiveRecord::Migration[7.2]
  def up
    unless column_exists?(:tender_line_items, :position)
      add_column :tender_line_items, :position, :integer, default: 0
    end

    # Initialize positions for existing records
    Tender.all.each do |tender|
      tender.tender_line_items.order(:created_at).each_with_index do |item, index|
        item.update_column(:position, index + 1)
      end
    end
  end

  def down
    # We don't want to remove the column if it was already there before this migration
    # but for completeness of the "Add" migration:
    if column_exists?(:tender_line_items, :position)
      remove_column :tender_line_items, :position
    end
  end
end
