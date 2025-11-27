class ConvertSectionCategoryToEnum < ActiveRecord::Migration[7.2]
  def up
    # Create the enum type
    execute <<-SQL
      CREATE TYPE section_category_enum AS ENUM (
        'Blank',
        'Steel Sections',
        'Paintwork',
        'Bolts',
        'Gutter Meter',
        'M16 Mechanical Anchor',
        'M16 Chemical',
        'M20 Chemical',
        'M24 Chemical',
        'M16 HD Bolt',
        'M20 HD Bolt',
        'M24 HD Bolt',
        'M30 HD Bolt',
        'M36 HD Bolt',
        'M42 HD Bolt'
      );
    SQL

    # Delete all existing data from boq_items
    execute "DELETE FROM boq_items;"

    # Alter the column to use the enum type
    execute "ALTER TABLE boq_items ALTER COLUMN section_category TYPE section_category_enum USING section_category::section_category_enum;"
  end

  def down
    # Convert back to string and drop enum type
    execute "ALTER TABLE boq_items ALTER COLUMN section_category TYPE varchar(255);"
    execute "DROP TYPE section_category_enum;"
  end
end
