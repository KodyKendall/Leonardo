class MigrateTenderLineItemSectionCategoryToTable < ActiveRecord::Migration[7.2]
  def up
    # 1. Add the foreign key column
    add_reference :tender_line_items, :section_category, foreign_key: true

    # 2. Backfill data
    # We need to map the enum string values to SectionCategory records.
    # The enum values match SectionCategory#display_name.
    execute <<-SQL
      UPDATE tender_line_items
      SET section_category_id = sc.id
      FROM section_categories sc
      WHERE tender_line_items.section_category::text = sc.display_name
    SQL

    # 3. Remove the old column
    remove_column :tender_line_items, :section_category
  end

  def down
    # Re-add the column as enum
    add_column :tender_line_items, :section_category, :enum, enum_type: "section_category_enum"

    # Restore data
    execute <<-SQL
      UPDATE tender_line_items
      SET section_category = sc.display_name::section_category_enum
      FROM section_categories sc
      WHERE tender_line_items.section_category_id = sc.id
    SQL

    # Remove the reference
    remove_reference :tender_line_items, :section_category
  end
end
