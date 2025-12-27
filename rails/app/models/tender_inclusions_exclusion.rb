class TenderInclusionsExclusion < ApplicationRecord
  belongs_to :tender

  after_save :sync_inclusions_to_rate_buildups

  private

  # Sync inclusion/exclusion checkbox values to all associated rate buildups
  # This ensures the Inclusions page is the single source of truth
  def sync_inclusions_to_rate_buildups
    return unless tender.present?

    # Define mapping between TenderInclusionsExclusion fields and LineItemRateBuildUp fields
    # Handles 4 field name mismatches:
    # - primer_included → shop_priming_included
    # - final_paint_included → onsite_painting_included
    # - cherry_pickers_included → cherry_picker_included (plural → singular)
    # - steel_galvanized → galvanizing_included
    field_mapping = {
      fabrication_included: :fabrication_included,
      overheads_included: :overheads_included,
      primer_included: :shop_priming_included,
      final_paint_included: :onsite_painting_included,
      delivery_included: :delivery_included,
      bolts_included: :bolts_included,
      erection_included: :erection_included,
      crainage_included: :crainage_included,
      cherry_pickers_included: :cherry_picker_included,
      steel_galvanized: :galvanizing_included
    }

    # Iterate through all tender line items for this tender
    tender.tender_line_items.each do |line_item|
      rate_buildup = line_item.line_item_rate_build_up
      next unless rate_buildup.present?

      # Build a hash of updates: convert boolean (true/false) to decimal (1.0/0.0)
      updates = {}
      field_mapping.each do |source_field, target_field|
        source_value = send(source_field)
        # Convert true → 1.0, false/nil → 0.0
        updates[target_field] = source_value ? 1.0 : 0.0
      end

      # Update all mapped fields at once
      # Use update_columns to avoid triggering callbacks on rate_buildup that would
      # create a recursive loop. Instead, manually trigger broadcast after all updates.
      rate_buildup.update_columns(updates)
    end

    # After all rate buildups are updated, trigger broadcasts for each line item
    # This ensures Builder page updates in real-time without page refresh
    tender.tender_line_items.each do |line_item|
      rate_buildup = line_item.line_item_rate_build_up
      next unless rate_buildup.present?

      # Manually invoke the private broadcast callback using send
      rate_buildup.send(:broadcast_to_tender_line_item)
    end
  end
end
