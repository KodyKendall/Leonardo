class ConvertAllBuildUpColumnsToDecimal < ActiveRecord::Migration[7.2]
  def change
    # Convert all boolean inclusion columns to decimal multipliers
    reversible do |dir|
      dir.up do
        # Drop old defaults, change types, and set new defaults
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN fabrication_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN fabrication_included TYPE decimal(5,2) USING (CASE WHEN fabrication_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN fabrication_included SET DEFAULT 1.0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN overheads_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN overheads_included TYPE decimal(5,2) USING (CASE WHEN overheads_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN overheads_included SET DEFAULT 1.0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN shop_priming_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN shop_priming_included TYPE decimal(5,2) USING (CASE WHEN shop_priming_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN shop_priming_included SET DEFAULT 0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN onsite_painting_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN onsite_painting_included TYPE decimal(5,2) USING (CASE WHEN onsite_painting_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN onsite_painting_included SET DEFAULT 0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN delivery_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN delivery_included TYPE decimal(5,2) USING (CASE WHEN delivery_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN delivery_included SET DEFAULT 1.0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN bolts_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN bolts_included TYPE decimal(5,2) USING (CASE WHEN bolts_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN bolts_included SET DEFAULT 1.0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN erection_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN erection_included TYPE decimal(5,2) USING (CASE WHEN erection_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN erection_included SET DEFAULT 1.0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN crainage_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN crainage_included TYPE decimal(5,2) USING (CASE WHEN crainage_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN crainage_included SET DEFAULT 0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN cherry_picker_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN cherry_picker_included TYPE decimal(5,2) USING (CASE WHEN cherry_picker_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN cherry_picker_included SET DEFAULT 1.0")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN galvanizing_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN galvanizing_included TYPE decimal(5,2) USING (CASE WHEN galvanizing_included THEN 1.0 ELSE 0 END)::decimal(5,2)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN galvanizing_included SET DEFAULT 0")
      end

      dir.down do
        # Reverse: Convert back to boolean
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN fabrication_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN fabrication_included TYPE boolean USING (fabrication_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN fabrication_included SET DEFAULT true")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN overheads_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN overheads_included TYPE boolean USING (overheads_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN overheads_included SET DEFAULT true")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN shop_priming_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN shop_priming_included TYPE boolean USING (shop_priming_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN shop_priming_included SET DEFAULT false")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN onsite_painting_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN onsite_painting_included TYPE boolean USING (onsite_painting_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN onsite_painting_included SET DEFAULT false")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN delivery_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN delivery_included TYPE boolean USING (delivery_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN delivery_included SET DEFAULT true")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN bolts_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN bolts_included TYPE boolean USING (bolts_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN bolts_included SET DEFAULT true")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN erection_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN erection_included TYPE boolean USING (erection_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN erection_included SET DEFAULT true")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN crainage_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN crainage_included TYPE boolean USING (crainage_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN crainage_included SET DEFAULT false")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN cherry_picker_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN cherry_picker_included TYPE boolean USING (cherry_picker_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN cherry_picker_included SET DEFAULT true")

        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN galvanizing_included DROP DEFAULT")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN galvanizing_included TYPE boolean USING (galvanizing_included::numeric > 0)")
        execute("ALTER TABLE line_item_rate_build_ups ALTER COLUMN galvanizing_included SET DEFAULT false")
      end
    end
  end
end
