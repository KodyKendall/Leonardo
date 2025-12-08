class CreatePurposeEnum < ActiveRecord::Migration[7.2]
  def up
    # Create the enum type for purpose with two options: splicing and main
    execute <<-SQL
      CREATE TYPE purpose_enum AS ENUM ('splicing', 'main');
    SQL

    # Convert any 'miscellaneous' values to 'main' before changing the column type
    execute "UPDATE tender_crane_selections SET purpose = 'main' WHERE purpose = 'miscellaneous';"

    # Remove the default before changing the column type
    execute "ALTER TABLE tender_crane_selections ALTER COLUMN purpose DROP DEFAULT;"

    # Change the purpose column from string to enum
    change_column :tender_crane_selections, :purpose, :enum, enum_type: 'purpose_enum', using: 'purpose::purpose_enum'

    # Set the default back to 'main'
    execute "ALTER TABLE tender_crane_selections ALTER COLUMN purpose SET DEFAULT 'main'::purpose_enum;"
  end

  def down
    # Remove the default before changing the column type
    execute "ALTER TABLE tender_crane_selections ALTER COLUMN purpose DROP DEFAULT;"

    # Change back to string
    change_column :tender_crane_selections, :purpose, :string, limit: 20

    # Set the default back to string value
    execute "ALTER TABLE tender_crane_selections ALTER COLUMN purpose SET DEFAULT 'main';"

    # Drop the enum type
    execute <<-SQL
      DROP TYPE purpose_enum;
    SQL
  end
end
