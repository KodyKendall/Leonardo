# This migration comes from llama_bot_rails (originally 20260212000008)
class CreateLlamaBotRailsTags < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_tags do |t|
      t.string :name, null: false
      t.string :color, default: '#6366f1'
      t.text :description

      t.timestamps
    end

    add_index :llama_bot_rails_tags, :name, unique: true
  end
end
