# This migration comes from llama_bot_rails (originally 20260815000001)
# The application event layer that sits above PaperTrail: one row per
# meaningful operation, whether or not it changed any audited record.
# See docs/activity_events.md.
class CreateLlamaBotRailsActivityEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_activity_events do |t|
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false

      # Actor ids are strings so a User (42), an agent ("leo") and a system
      # component all fit one column without a polymorphic join.
      t.string :actor_type
      t.string :actor_id
      t.string :actor_label

      t.string :subject_type
      t.string :subject_id
      t.string :subject_label

      t.string :workspace_id

      t.string :source, null: false, default: "system"

      t.string :request_id
      t.string :correlation_id
      t.bigint :parent_event_id

      t.string :controller
      t.string :action

      t.string :job_class
      t.string :job_id

      t.string :trigger_type
      t.string :trigger_name

      # Denormalized "a human did this", so adoption queries are one index scan
      # instead of a source/actor_type predicate over millions of rows.
      t.boolean :human, null: false, default: false
      t.integer :changed_records_count, null: false, default: 0

      t.public_send(json_column_type, :metadata, null: false, default: {})

      t.datetime :created_at, null: false
    end

    add_index :llama_bot_rails_activity_events, [ :workspace_id, :occurred_at ],
              name: "idx_llama_activity_workspace"
    add_index :llama_bot_rails_activity_events, [ :actor_type, :actor_id, :occurred_at ],
              name: "idx_llama_activity_actor"
    add_index :llama_bot_rails_activity_events, [ :subject_type, :subject_id, :occurred_at ],
              name: "idx_llama_activity_subject"
    add_index :llama_bot_rails_activity_events, [ :event_type, :occurred_at ],
              name: "idx_llama_activity_type"
    # Adoption: "meaningful human actions in this workspace since X".
    add_index :llama_bot_rails_activity_events, [ :human, :workspace_id, :occurred_at ],
              name: "idx_llama_activity_human"
    add_index :llama_bot_rails_activity_events, :correlation_id,
              name: "idx_llama_activity_correlation"
    add_index :llama_bot_rails_activity_events, :request_id,
              name: "idx_llama_activity_request"
    add_index :llama_bot_rails_activity_events, :parent_event_id,
              name: "idx_llama_activity_parent"
  end

  private

  # jsonb where we have it (every real LlamaPress app is Postgres); json keeps
  # the migration loadable on sqlite for the engine's dummy app.
  def json_column_type
    connection.adapter_name.downcase.include?("postg") ? :jsonb : :json
  end
end
