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

ActiveRecord::Schema[7.2].define(version: 2025_11_06_121225) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "activities", force: :cascade do |t|
    t.bigint "flow_id", null: false
    t.string "activity_type"
    t.string "description"
    t.datetime "activity_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flow_id"], name: "index_activities_on_flow_id"
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

  create_table "flow_metrics", force: :cascade do |t|
    t.bigint "flow_id", null: false
    t.string "week_label"
    t.integer "sends"
    t.integer "opens"
    t.integer "clicks"
    t.date "metric_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flow_id"], name: "index_flow_metrics_on_flow_id"
  end

  create_table "flows", force: :cascade do |t|
    t.string "name"
    t.integer "sends"
    t.decimal "open_rate"
    t.decimal "click_rate"
    t.decimal "revenue"
    t.string "status"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_flows_on_user_id"
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
    t.index ["awarded_project_id"], name: "index_tenders_on_awarded_project_id"
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
  add_foreign_key "activities", "flows"
  add_foreign_key "budget_allowances", "budget_categories"
  add_foreign_key "budget_allowances", "projects"
  add_foreign_key "claim_line_items", "claims"
  add_foreign_key "claims", "projects"
  add_foreign_key "claims", "users", column: "submitted_by_id"
  add_foreign_key "fabrication_records", "projects"
  add_foreign_key "flow_metrics", "flows"
  add_foreign_key "flows", "users"
  add_foreign_key "projects", "tenders"
  add_foreign_key "projects", "users", column: "created_by_id"
  add_foreign_key "tenders", "projects", column: "awarded_project_id"
  add_foreign_key "variation_orders", "projects"
  add_foreign_key "variation_orders", "users", column: "approved_by_id"
  add_foreign_key "variation_orders", "users", column: "created_by_id"
end
