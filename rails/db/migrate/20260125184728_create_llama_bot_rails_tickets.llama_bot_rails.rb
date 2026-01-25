# This migration comes from llama_bot_rails (originally 20260125000000)
class CreateLlamaBotRailsTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_tickets do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: 'backlog'
      t.integer :position
      t.text :notes
      t.integer :agent_result
      t.text :agent_notes
      t.string :langsmith_url
      t.integer :ticket_type

      t.timestamps
    end

    add_index :llama_bot_rails_tickets, :status
    add_index :llama_bot_rails_tickets, :position
  end
end
