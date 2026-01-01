class TenderInclusionsExclusion < ApplicationRecord
  belongs_to :tender

  after_update :sync_inclusions_to_rate_buildups

  private

  # Sync inclusion/exclusion checkbox values to all associated rate buildups
  # This ensures the Inclusions page is the single source of truth
  def sync_inclusions_to_rate_buildups
    return unless tender.present?

    # Define mapping between TenderInclusionsExclusion fields and LineItemRateBuildUp fields
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

    # Only sync fields that were actually changed in this update
    changed_mapping = field_mapping.select { |source_field, _| saved_changes.key?(source_field.to_s) }
    return if changed_mapping.empty?

    # Use a JOIN to find all rate buildups for this tender's line items
    # This avoids transaction isolation issues with separate queries
    rate_buildups = LineItemRateBuildUp
      .joins(:tender_line_item)
      .where(tender_line_items: { tender_id: tender.id })
    
    rate_buildups.each do |rate_buildup|
      # Build a hash of updates: convert boolean (true/false) to decimal (1.0/0.0)
      updates = {}
      changed_mapping.each do |source_field, target_field|
        source_value = send(source_field)
        updates[target_field] = source_value ? 1.0 : 0.0
      end

      # Update only the changed fields using update_columns to bypass callbacks
      # This prevents recursive loops and preserves the 0.0 values (excluded)
      rate_buildup.update_columns(updates)
      
      # Reload to get the updated values in memory before recalculating
      rate_buildup.reload
      
      # Recalculate derived totals
      # This will trigger before_save callbacks which normalize_multipliers, but since
      # we now only normalize nil (not 0.0), excluded items stay excluded
      rate_buildup.recalculate_totals!
    end
  end
end
