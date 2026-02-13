# This migration comes from llama_bot_rails (originally 20260212000009)
class CreateLlamaBotRailsTaggings < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_taggings do |t|
      t.references :tag,
                   null: false,
                   foreign_key: { to_table: :llama_bot_rails_tags },
                   index: true
      t.references :taggable, polymorphic: true, null: false
      t.integer :tagged_by_user_id

      t.timestamps
    end

    add_index :llama_bot_rails_taggings, [:taggable_type, :taggable_id, :tag_id],
              unique: true, name: 'index_taggings_on_taggable_and_tag'
  end
end
