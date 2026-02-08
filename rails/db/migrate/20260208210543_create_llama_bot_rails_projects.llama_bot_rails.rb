# This migration comes from llama_bot_rails (originally 20260125000003)
class CreateLlamaBotRailsProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_projects do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :llama_bot_rails_projects, :name

    # Add foreign key to tickets
    add_reference :llama_bot_rails_tickets, :project,
                  foreign_key: { to_table: :llama_bot_rails_projects },
                  null: true,
                  index: true
  end
end
