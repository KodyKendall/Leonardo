# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_12_12_172528) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "purpose_enum", ["splicing", "main"]
  create_enum "section_category_enum", ["Blank", "Steel Sections", "Paintwork", "Bolts", "Gutter Meter", "M16 Mechanical Anchor", "M16 Chemical", "M20 Chemical", "M24 Chemical", "M16 HD Bolt", "M20 HD Bolt", "M24 HD Bolt", "M30 HD Bolt", "M36 HD Bolt", "M42 HD Bolt"]

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "boq_items", force: :cascade do |t|
    t.bigint "boq_id", null: false
    t.string "item_number"
    t.text "item_description"
    t.string "unit_of_measure"
    t.decimal "quantity", precision: 10, scale: 3, default: "0.0"
    t.enum "section_category", enum_type: "section_category_enum"
    t.integer "sequence_order"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "page_number"
    t.index ["boq_id"], name: "index_boq_items_on_boq_id"
  end

  create_table "boqs", force: :cascade do |t|
    t.string "boq_name", null: false
    t.string "file_name", null: false
    t.string "file_path"
    t.string "status", default: "uploaded", null: false
    t.string "client_name"
    t.string "client_reference"
    t.string "qs_name"
    t.text "notes"
    t.date "received_date"
    t.bigint "uploaded_by_id"
    t.datetime "parsed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "header_row_index", default: 0
    t.bigint "tender_id"
    t.index ["status"], name: "index_boqs_on_status"
    t.index ["tender_id"], name: "index_boqs_on_tender_id"
    t.index ["uploaded_by_id"], name: "index_boqs_on_uploaded_by_id"
  end

  create_table "budget_allowances", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "budget_category_id", null: false
    t.decimal "budgeted_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "actual_spend", precision: 12, scale: 2, default: "0.0"
    t.decimal "variance", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_category_id"], name: "index_budget_allowances_on_budget_category_id"
    t.index ["project_id", "budget_category_id"], name: "index_budget_allowances_on_project_id_and_budget_category_id", unique: true
    t.index ["project_id"], name: "index_budget_allowances_on_project_id"
  end

  create_table "budget_categories", force: :cascade do |t|
    t.string "category_name", null: false
    t.string "cost_code"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_name"], name: "index_budget_categories_on_category_name", unique: true
    t.index ["cost_code"], name: "index_budget_categories_on_cost_code"
  end

  create_table "checkpoint_blobs", primary_key: ["thread_id", "checkpoint_ns", "channel", "version"], force: :cascade do |t|
    t.text "thread_id", null: false
    t.text "checkpoint_ns", default: "", null: false
    t.text "channel", null: false
    t.text "version", null: false
    t.text "type", null: false
    t.binary "blob"
    t.index ["thread_id"], name: "checkpoint_blobs_thread_id_idx"
  end

  create_table "checkpoint_migrations", primary_key: "v", id: :integer, default: nil, force: :cascade do |t|
  end

  create_table "checkpoint_writes", primary_key: ["thread_id", "checkpoint_ns", "checkpoint_id", "task_id", "idx"], force: :cascade do |t|
    t.text "thread_id", null: false
    t.text "checkpoint_ns", default: "", null: false
    t.text "checkpoint_id", null: false
    t.text "task_id", null: false
    t.integer "idx", null: false
    t.text "channel", null: false
    t.text "type"
    t.binary "blob", null: false
    t.text "task_path", default: "", null: false
    t.index ["thread_id"], name: "checkpoint_writes_thread_id_idx"
  end

  create_table "checkpoints", primary_key: ["thread_id", "checkpoint_ns", "checkpoint_id"], force: :cascade do |t|
    t.text "thread_id", null: false
    t.text "checkpoint_ns", default: "", null: false
    t.text "checkpoint_id", null: false
    t.text "parent_checkpoint_id"
    t.text "type"
    t.jsonb "checkpoint", null: false
    t.jsonb "metadata", default: {}, null: false
    t.index ["thread_id"], name: "checkpoints_thread_id_idx"
  end

  create_table "claim_line_items", force: :cascade do |t|
    t.bigint "claim_id", null: false
    t.string "line_item_description"
    t.decimal "tender_rate", precision: 12, scale: 2
    t.decimal "claimed_quantity", precision: 10, scale: 3, default: "0.0"
    t.decimal "claimed_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "cumulative_quantity", precision: 10, scale: 3, default: "0.0"
    t.boolean "is_new_item", default: false
    t.decimal "price_escalation", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_claim_line_items_on_claim_id"
  end

  create_table "claims", force: :cascade do |t|
    t.string "claim_number", null: false
    t.bigint "project_id", null: false
    t.date "claim_date", null: false
    t.string "claim_status", default: "draft", null: false
    t.decimal "total_claimed", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_paid", precision: 12, scale: 2, default: "0.0"
    t.decimal "amount_due", precision: 12, scale: 2, default: "0.0"
    t.bigint "submitted_by_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_number"], name: "index_claims_on_claim_number", unique: true
    t.index ["claim_status"], name: "index_claims_on_claim_status"
    t.index ["project_id", "claim_date"], name: "index_claims_on_project_id_and_claim_date"
    t.index ["project_id"], name: "index_claims_on_project_id"
    t.index ["submitted_by_id"], name: "index_claims_on_submitted_by_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "business_name"
    t.string "contact_name"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "crane_complements", force: :cascade do |t|
    t.decimal "area_min_sqm", precision: 10, scale: 2, null: false
    t.decimal "area_max_sqm", precision: 10, scale: 2, null: false
    t.string "crane_recommendation", limit: 100, null: false
    t.decimal "default_wet_rate_per_day", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "crane_rates", force: :cascade do |t|
    t.string "size", null: false
    t.string "ownership_type", default: "rental", null: false
    t.decimal "dry_rate_per_day", precision: 12, scale: 2, null: false
    t.decimal "diesel_per_day", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "is_active", default: true
    t.date "effective_from", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "destroys", force: :cascade do |t|
    t.string "CraneRequirements"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fabrication_records", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.date "record_month", null: false
    t.decimal "tonnes_fabricated", precision: 10, scale: 3, default: "0.0"
    t.decimal "allowed_rate", precision: 12, scale: 2, default: "0.0"
    t.decimal "allowed_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "actual_spend", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "record_month"], name: "index_fabrication_records_on_project_id_and_record_month", unique: true
    t.index ["project_id"], name: "index_fabrication_records_on_project_id"
  end

  create_table "line_item_material_breakdowns", force: :cascade do |t|
    t.bigint "tender_line_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "margin_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["tender_line_item_id"], name: "index_line_item_material_breakdowns_on_tender_line_item_id"
  end

  create_table "line_item_materials", force: :cascade do |t|
    t.bigint "tender_line_item_id", null: false
    t.bigint "material_supply_id"
    t.decimal "proportion", precision: 5, scale: 4, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "line_item_material_breakdown_id", null: false
    t.decimal "waste_percentage", precision: 5, scale: 2, default: "0.0"
    t.decimal "rate"
    t.decimal "quantity"
    t.index ["line_item_material_breakdown_id"], name: "index_line_item_materials_on_line_item_material_breakdown_id"
    t.index ["material_supply_id"], name: "index_line_item_materials_on_material_supply_id"
    t.index ["tender_line_item_id", "material_supply_id"], name: "idx_on_tender_line_item_id_material_supply_id_beb386dde4"
    t.index ["tender_line_item_id"], name: "index_line_item_materials_on_tender_line_item_id"
  end

  create_table "line_item_rate_build_ups", force: :cascade do |t|
    t.bigint "tender_line_item_id", null: false
    t.decimal "material_supply_rate", precision: 12, scale: 2, default: "0.0"
    t.decimal "fabrication_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "fabrication_included", default: true
    t.decimal "overheads_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "overheads_included", default: true
    t.decimal "shop_priming_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "shop_priming_included", default: false
    t.decimal "onsite_painting_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "onsite_painting_included", default: false
    t.decimal "delivery_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "delivery_included", default: true
    t.decimal "bolts_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "bolts_included", default: true
    t.decimal "erection_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "erection_included", default: true
    t.decimal "crainage_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "crainage_included", default: false
    t.decimal "cherry_picker_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "cherry_picker_included", default: true
    t.decimal "galvanizing_rate", precision: 12, scale: 2, default: "0.0"
    t.boolean "galvanizing_included", default: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0"
    t.decimal "margin_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_before_rounding", precision: 12, scale: 2, default: "0.0"
    t.decimal "rounded_rate", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "material_supply_included", default: true
    t.decimal "margin_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["tender_line_item_id"], name: "index_line_item_rate_build_ups_on_tender_line_item_id"
  end

  create_table "material_supplies", force: :cascade do |t|
    t.string "name"
    t.decimal "waste_percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "material_supply_rates", force: :cascade do |t|
    t.decimal "rate"
    t.string "unit"
    t.bigint "material_supply_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "monthly_material_supply_rate_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_supply_id"], name: "index_material_supply_rates_on_material_supply_id"
    t.index ["monthly_material_supply_rate_id"], name: "index_material_supply_rates_on_monthly_material_supply_rate_id"
    t.index ["supplier_id"], name: "index_material_supply_rates_on_supplier_id"
  end

  create_table "monthly_material_supply_rates", force: :cascade do |t|
    t.date "effective_from"
    t.date "effective_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "on_site_mobile_crane_breakdowns", force: :cascade do |t|
    t.bigint "tender_id", null: false
    t.decimal "total_roof_area_sqm", precision: 12, scale: 2, default: "0.0"
    t.decimal "erection_rate_sqm_per_day", precision: 10, scale: 2, default: "0.0"
    t.integer "program_duration_days", default: 0
    t.string "ownership_type", limit: 20, default: "rental"
    t.boolean "splicing_crane_required", default: false
    t.string "splicing_crane_size", limit: 10
    t.integer "splicing_crane_days", default: 0
    t.boolean "misc_crane_required", default: false
    t.string "misc_crane_size", limit: 10
    t.integer "misc_crane_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tender_id"], name: "index_on_site_mobile_crane_breakdowns_on_tender_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "rsb_number", null: false
    t.bigint "tender_id", null: false
    t.string "project_status", default: "active", null: false
    t.date "project_start_date"
    t.date "project_end_date"
    t.decimal "budget_total", precision: 12, scale: 2
    t.decimal "actual_spend", precision: 12, scale: 2, default: "0.0"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_projects_on_created_by_id"
    t.index ["project_status"], name: "index_projects_on_project_status"
    t.index ["rsb_number"], name: "index_projects_on_rsb_number", unique: true
    t.index ["tender_id"], name: "index_projects_on_tender_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tender_crane_selections", force: :cascade do |t|
    t.bigint "tender_id", null: false
    t.bigint "crane_rate_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "purpose", default: "main", null: false, enum_type: "purpose_enum"
    t.integer "quantity", default: 1, null: false
    t.integer "duration_days", null: false
    t.decimal "wet_rate_per_day", precision: 12, scale: 2, null: false
    t.decimal "total_cost", precision: 14, scale: 2, default: "0.0"
    t.integer "sort_order", default: 0
    t.bigint "on_site_mobile_crane_breakdown_id"
    t.index ["crane_rate_id"], name: "index_tender_crane_selections_on_crane_rate_id"
    t.index ["on_site_mobile_crane_breakdown_id"], name: "idx_on_on_site_mobile_crane_breakdown_id_69b25fc54e"
    t.index ["tender_id"], name: "index_tender_crane_selections_on_tender_id"
  end

  create_table "tender_inclusions_exclusions", force: :cascade do |t|
    t.bigint "tender_id", null: false
    t.boolean "fabrication_included"
    t.boolean "overheads_included"
    t.boolean "primer_included"
    t.boolean "final_paint_included"
    t.boolean "delivery_included"
    t.boolean "bolts_included"
    t.boolean "erection_included"
    t.boolean "crainage_included"
    t.boolean "cherry_pickers_included"
    t.boolean "steel_galvanized"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tender_id"], name: "index_tender_inclusions_exclusions_on_tender_id"
  end

  create_table "tender_line_items", force: :cascade do |t|
    t.bigint "tender_id", null: false
    t.decimal "quantity", precision: 12, scale: 2, default: "0.0"
    t.decimal "rate", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "page_number"
    t.string "item_number"
    t.text "item_description"
    t.string "unit_of_measure"
    t.enum "section_category", enum_type: "section_category_enum"
    t.text "notes"
    t.index ["tender_id"], name: "index_tender_line_items_on_tender_id"
  end

  create_table "tenders", force: :cascade do |t|
    t.string "e_number", null: false
    t.string "status", default: "draft", null: false
    t.string "client_name"
    t.decimal "tender_value", precision: 12, scale: 2
    t.string "project_type", default: "commercial"
    t.text "notes"
    t.bigint "awarded_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qob_file"
    t.string "tender_name"
    t.bigint "client_id"
    t.date "submission_deadline"
    t.decimal "grand_total", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_tonnage", precision: 12, scale: 3, default: "0.0"
    t.index ["awarded_project_id"], name: "index_tenders_on_awarded_project_id"
    t.index ["client_id"], name: "index_tenders_on_client_id"
    t.index ["e_number"], name: "index_tenders_on_e_number", unique: true
    t.index ["status"], name: "index_tenders_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "twilio_number"
    t.boolean "admin"
    t.string "api_token"
    t.string "role", default: "project_manager", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "variation_orders", force: :cascade do |t|
    t.string "vo_number", null: false
    t.bigint "project_id", null: false
    t.string "vo_status", default: "draft", null: false
    t.decimal "vo_amount", precision: 12, scale: 2, null: false
    t.text "description"
    t.bigint "created_by_id"
    t.bigint "approved_by_id"
    t.text "approver_notes"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_variation_orders_on_approved_by_id"
    t.index ["created_by_id"], name: "index_variation_orders_on_created_by_id"
    t.index ["project_id", "vo_status"], name: "index_variation_orders_on_project_id_and_vo_status"
    t.index ["project_id"], name: "index_variation_orders_on_project_id"
    t.index ["vo_number"], name: "index_variation_orders_on_vo_number", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "boq_items", "boqs"
  add_foreign_key "boqs", "tenders"
  add_foreign_key "boqs", "users", column: "uploaded_by_id"
  add_foreign_key "budget_allowances", "budget_categories"
  add_foreign_key "budget_allowances", "projects"
  add_foreign_key "claim_line_items", "claims"
  add_foreign_key "claims", "projects"
  add_foreign_key "claims", "users", column: "submitted_by_id"
  add_foreign_key "fabrication_records", "projects"
  add_foreign_key "line_item_material_breakdowns", "tender_line_items"
  add_foreign_key "line_item_materials", "line_item_material_breakdowns"
  add_foreign_key "line_item_materials", "material_supplies"
  add_foreign_key "line_item_materials", "tender_line_items"
  add_foreign_key "line_item_rate_build_ups", "tender_line_items"
  add_foreign_key "material_supply_rates", "material_supplies"
  add_foreign_key "material_supply_rates", "monthly_material_supply_rates"
  add_foreign_key "material_supply_rates", "suppliers"
  add_foreign_key "on_site_mobile_crane_breakdowns", "tenders", on_delete: :cascade
  add_foreign_key "projects", "tenders"
  add_foreign_key "projects", "users", column: "created_by_id"
  add_foreign_key "tender_crane_selections", "crane_rates"
  add_foreign_key "tender_crane_selections", "on_site_mobile_crane_breakdowns"
  add_foreign_key "tender_crane_selections", "tenders"
  add_foreign_key "tender_inclusions_exclusions", "tenders"
  add_foreign_key "tender_line_items", "tenders"
  add_foreign_key "tenders", "clients"
  add_foreign_key "tenders", "projects", column: "awarded_project_id"
  add_foreign_key "variation_orders", "projects"
  add_foreign_key "variation_orders", "users", column: "approved_by_id"
  add_foreign_key "variation_orders", "users", column: "created_by_id"
end
