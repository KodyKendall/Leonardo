# This migration comes from llama_bot_rails (originally 20260125000001)
class AddResearchNotesToLlamaBotRailsTickets < ActiveRecord::Migration[7.2]
  def change
    add_column :llama_bot_rails_tickets, :research_notes, :text
  end
end
