# This migration comes from llama_bot_rails (originally 20260815000002)
# PaperTrail's `versions` table, plus the four correlation columns that let a
# row-level change be traced back to the operation that caused it.
#
# Idempotent on purpose: apps that already ran PaperTrail's own installer keep
# their table and only gain the correlation columns. Class name is prefixed
# (while the TABLE stays `versions`) so it can never collide with a host app's
# own CreateVersions migration — Rails rejects duplicate migration class names.
class CreateLlamaBotRailsVersions < ActiveRecord::Migration[7.2]
  def up
    unless table_exists?(:versions)
      create_table :versions do |t|
        t.string :item_type, null: false
        # String, not bigint: works unchanged for integer, uuid and composite
        # primary keys. ActiveRecord casts on both write and lookup.
        t.string :item_id, null: false
        t.string :event, null: false
        t.string :whodunnit
        t.public_send(json_column_type, :object)
        t.public_send(json_column_type, :object_changes)
        t.datetime :created_at
      end

      add_index :versions, [ :item_type, :item_id, :created_at ],
                name: "idx_versions_item"
      add_index :versions, :whodunnit, name: "idx_versions_whodunnit"
    end

    add_column :versions, :correlation_id, :string unless column_exists?(:versions, :correlation_id)
    add_column :versions, :request_id, :string unless column_exists?(:versions, :request_id)
    add_column :versions, :source, :string unless column_exists?(:versions, :source)
    add_column :versions, :activity_event_id, :bigint unless column_exists?(:versions, :activity_event_id)

    unless index_exists?(:versions, :correlation_id, name: "idx_versions_correlation")
      add_index :versions, :correlation_id, name: "idx_versions_correlation"
    end
    unless index_exists?(:versions, :activity_event_id, name: "idx_versions_activity_event")
      add_index :versions, :activity_event_id, name: "idx_versions_activity_event"
    end
  end

  def down
    # Only ever drop what this migration is certain it added: an app that had
    # PaperTrail before us must keep its history through a rollback.
    remove_index :versions, name: "idx_versions_correlation" if index_exists?(:versions, :correlation_id, name: "idx_versions_correlation")
    remove_index :versions, name: "idx_versions_activity_event" if index_exists?(:versions, :activity_event_id, name: "idx_versions_activity_event")

    %i[correlation_id request_id source activity_event_id].each do |column|
      remove_column :versions, column if column_exists?(:versions, column)
    end
  end

  private

  # jsonb object/object_changes make version diffs queryable and sidestep the
  # YAML-serializer permitted-classes problem entirely; PaperTrail detects the
  # column type and skips its serializer.
  def json_column_type
    connection.adapter_name.downcase.include?("postg") ? :jsonb : :text
  end
end
