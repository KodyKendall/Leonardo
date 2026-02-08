# This migration comes from llama_bot_rails (originally 20260125000004)
class CreateLlamaBotRailsTicketComments < ActiveRecord::Migration[7.2]
  def change
    create_table :llama_bot_rails_ticket_comments do |t|
      t.references :ticket,
                   null: false,
                   foreign_key: { to_table: :llama_bot_rails_tickets },
                   index: true
      t.text :body, null: false
      t.integer :user_id
      t.string :author_name

      t.timestamps
    end

    add_index :llama_bot_rails_ticket_comments, :user_id
  end
end
