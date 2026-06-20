# This migration comes from llama_bot_rails (originally 20260615000001)
class CreateLlamaBotRailsReleases < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_releases do |t|
      t.string :version, null: false
      t.string :title
      t.text :notes
      t.boolean :published, null: false, default: false
      t.datetime :released_at
      t.datetime :emailed_at

      t.timestamps
    end

    add_index :llama_bot_rails_releases, :version, unique: true
    add_index :llama_bot_rails_releases, :released_at
  end
end
