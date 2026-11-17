# This migration comes from llama_bot_rails (originally 20261109000001)
# Institution-set password policy, password history, account lockout and the audit
# log's source IP column (HECVAT AAAI-03, AAAI-09, LP-31).
class CreateLlamaBotRailsAccountSecurity < ActiveRecord::Migration[7.0]
  def up
    create_table :llama_bot_rails_security_settings do |t|
      t.integer :password_min_length, null: false
      t.string :password_required_classes, null: false, default: ""
      t.integer :password_history_count, null: false
      t.string :updated_by_id
      t.timestamps
    end

    create_table :llama_bot_rails_password_histories do |t|
      t.bigint :user_id, null: false
      t.string :encrypted_password, null: false
      t.datetime :created_at, null: false
    end
    add_index :llama_bot_rails_password_histories, [ :user_id, :created_at ],
              name: "idx_llama_password_history_user"

    # Devise :lockable. Unused until a lockout is configured.
    add_column :users, :failed_attempts, :integer, default: 0, null: false unless column_exists?(:users, :failed_attempts)
    add_column :users, :locked_at, :datetime unless column_exists?(:users, :locked_at)
    add_column :users, :unlock_token, :string unless column_exists?(:users, :unlock_token)

    # "Who signed in from this IP" as one indexed query.
    add_column :llama_bot_rails_activity_events, :source_ip, :string
    add_index :llama_bot_rails_activity_events, :source_ip, name: "idx_llama_activity_source_ip"
    backfill_source_ip
  end

  def down
    remove_index :llama_bot_rails_activity_events, name: "idx_llama_activity_source_ip"
    remove_column :llama_bot_rails_activity_events, :source_ip
    remove_column :users, :unlock_token
    remove_column :users, :locked_at
    remove_column :users, :failed_attempts
    drop_table :llama_bot_rails_password_histories
    drop_table :llama_bot_rails_security_settings
  end

  private

  # Older events carry the IP in metadata only. One statement; Leo box tables are small.
  def backfill_source_ip
    table = :llama_bot_rails_activity_events
    if connection.adapter_name.downcase.include?("postg")
      execute "UPDATE #{table} SET source_ip = metadata->>'ip' WHERE source_ip IS NULL AND metadata ? 'ip'"
    elsif connection.adapter_name.downcase.include?("sqlite")
      execute "UPDATE #{table} SET source_ip = json_extract(metadata, '$.ip') WHERE source_ip IS NULL"
    end
  end
end
