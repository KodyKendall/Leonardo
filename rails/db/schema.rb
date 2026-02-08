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

ActiveRecord::Schema[7.2].define(version: 2026_02_08_210545) do
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

  create_table "llama_bot_rails_projects", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_llama_bot_rails_projects_on_name"
  end

  create_table "llama_bot_rails_ticket_comments", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.text "body", null: false
    t.integer "user_id"
    t.string "author_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_llama_bot_rails_ticket_comments_on_ticket_id"
    t.index ["user_id"], name: "index_llama_bot_rails_ticket_comments_on_user_id"
  end

  create_table "llama_bot_rails_ticket_traces", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.string "langsmith_url"
    t.string "langsmith_run_id"
    t.integer "trace_type", default: 0
    t.integer "tokens_used"
    t.string "model"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["langsmith_run_id"], name: "index_llama_bot_rails_ticket_traces_on_langsmith_run_id"
    t.index ["ticket_id"], name: "index_llama_bot_rails_ticket_traces_on_ticket_id"
    t.index ["trace_type"], name: "index_llama_bot_rails_ticket_traces_on_trace_type"
  end

  create_table "llama_bot_rails_tickets", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "backlog", null: false
    t.integer "position"
    t.text "notes"
    t.integer "agent_result"
    t.text "agent_notes"
    t.string "langsmith_url"
    t.integer "ticket_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "research_notes"
    t.integer "tokens_to_create_ticket"
    t.integer "tokens_to_implement_ticket"
    t.string "llm_model"
    t.datetime "work_started_at"
    t.datetime "work_completed_at"
    t.integer "points_estimate"
    t.decimal "points_actual", precision: 10, scale: 2
    t.bigint "project_id"
    t.index ["llm_model"], name: "index_llama_bot_rails_tickets_on_llm_model"
    t.index ["position"], name: "index_llama_bot_rails_tickets_on_position"
    t.index ["project_id"], name: "index_llama_bot_rails_tickets_on_project_id"
    t.index ["status"], name: "index_llama_bot_rails_tickets_on_status"
    t.index ["work_completed_at"], name: "index_llama_bot_rails_tickets_on_work_completed_at"
    t.index ["work_started_at"], name: "index_llama_bot_rails_tickets_on_work_started_at"
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
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "llama_bot_rails_ticket_comments", "llama_bot_rails_tickets", column: "ticket_id"
  add_foreign_key "llama_bot_rails_ticket_traces", "llama_bot_rails_tickets", column: "ticket_id"
  add_foreign_key "llama_bot_rails_tickets", "llama_bot_rails_projects", column: "project_id"
end
