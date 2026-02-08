# This migration comes from llama_bot_rails (originally 20260125000005)
class CreateLlamaBotRailsTicketTraces < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_ticket_traces do |t|
      t.references :ticket,
                   null: false,
                   foreign_key: { to_table: :llama_bot_rails_tickets },
                   index: true
      t.string :langsmith_url
      t.string :langsmith_run_id
      t.integer :trace_type, default: 0
      t.integer :tokens_used
      t.string :model

      t.timestamps
    end

    add_index :llama_bot_rails_ticket_traces, :trace_type
    add_index :llama_bot_rails_ticket_traces, :langsmith_run_id
  end
end
