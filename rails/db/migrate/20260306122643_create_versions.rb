# frozen_string_literal: true

# This migration creates the versions table for PaperTrail
# https://github.com/paper-trail-gem/paper_trail
class CreateVersions < ActiveRecord::Migration[7.2]
  def change
    create_table :versions do |t|
      t.string   :item_type, null: false
      t.bigint   :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.jsonb    :object          # Stores the previous version of the record
      t.jsonb    :object_changes  # Stores the changes made (optional, for update events)
      t.datetime :created_at
    end

    add_index :versions, %i[item_type item_id]
    add_index :versions, :created_at
  end
end
