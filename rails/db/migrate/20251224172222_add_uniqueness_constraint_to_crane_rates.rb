class AddUniquenessConstraintToCraneRates < ActiveRecord::Migration[7.2]
  def change
    # Step 1: Find duplicate crane rate IDs to delete (keep only most recent per size/ownership)
    duplicate_ids = execute(<<-SQL).map { |row| row['id'] }
      SELECT id FROM crane_rates
      WHERE id NOT IN (
        SELECT id FROM (
          SELECT DISTINCT ON (size, ownership_type) id
          FROM crane_rates
          ORDER BY size, ownership_type, effective_from DESC, id DESC
        ) AS latest_rates
      );
    SQL

    # Step 2: Delete tender crane selections that reference the duplicate crane rates
    if duplicate_ids.any?
      execute("DELETE FROM tender_crane_selections WHERE crane_rate_id IN (#{duplicate_ids.join(',')})")
    end

    # Step 3: Delete the duplicate crane rates
    if duplicate_ids.any?
      execute("DELETE FROM crane_rates WHERE id IN (#{duplicate_ids.join(',')})")
    end

    # Step 4: Add unique constraint on (size, ownership_type)
    add_index :crane_rates, [:size, :ownership_type], unique: true, name: 'index_crane_rates_on_size_and_ownership_type'
  end
end
