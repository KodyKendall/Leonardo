# This migration comes from llama_bot_rails (originally 20261106000001)
class AddAdministrativeRolesToUsers < ActiveRecord::Migration[7.0]
  # Separation of duties (HECVAT APPL-05). users.admin stays, as the account owner.
  def change
    add_column :users, :security_admin, :boolean, default: false, null: false
    add_column :users, :system_admin, :boolean, default: false, null: false
  end
end
