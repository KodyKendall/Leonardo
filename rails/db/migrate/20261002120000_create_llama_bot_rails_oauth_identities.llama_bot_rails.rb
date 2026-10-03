# This migration comes from llama_bot_rails (originally 20261002000001)
class CreateLlamaBotRailsOauthIdentities < ActiveRecord::Migration[7.0]
  # "Sign in with Google / Microsoft": one row per provider account linked to a
  # user. A separate table (not provider/uid columns on users) so one user can
  # link more than one provider. Lookups are always provider + uid, never email.
  def change
    create_table :llama_bot_rails_oauth_identities do |t|
      t.references :user, null: false, index: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.timestamps
    end
    add_index :llama_bot_rails_oauth_identities, [:provider, :uid], unique: true
  end
end
