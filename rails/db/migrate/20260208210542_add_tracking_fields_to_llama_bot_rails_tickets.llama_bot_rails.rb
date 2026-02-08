# This migration comes from llama_bot_rails (originally 20260125000002)
class AddTrackingFieldsToLlamaBotRailsTickets < ActiveRecord::Migration[7.2]
  def change
    # LLM/Cost tracking (typically filled by external system)
    add_column :llama_bot_rails_tickets, :tokens_to_create_ticket, :integer
    add_column :llama_bot_rails_tickets, :tokens_to_implement_ticket, :integer
    add_column :llama_bot_rails_tickets, :llm_model, :string
    add_column :llama_bot_rails_tickets, :work_started_at, :datetime
    add_column :llama_bot_rails_tickets, :work_completed_at, :datetime

    # Points system
    add_column :llama_bot_rails_tickets, :points_estimate, :integer
    add_column :llama_bot_rails_tickets, :points_actual, :decimal, precision: 10, scale: 2

    # Indexes for common queries
    add_index :llama_bot_rails_tickets, :work_started_at
    add_index :llama_bot_rails_tickets, :work_completed_at
    add_index :llama_bot_rails_tickets, :llm_model
  end
end
