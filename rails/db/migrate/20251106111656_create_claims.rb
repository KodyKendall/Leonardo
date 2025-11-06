class CreateClaims < ActiveRecord::Migration[7.2]
  def change
    create_table :claims do |t|
      t.string :claim_number, null: false
      t.references :project, foreign_key: true, null: false
      t.date :claim_date, null: false
      t.string :claim_status, default: "draft", null: false
      t.decimal :total_claimed, precision: 12, scale: 2, default: 0
      t.decimal :total_paid, precision: 12, scale: 2, default: 0
      t.decimal :amount_due, precision: 12, scale: 2, default: 0
      t.bigint :submitted_by_id
      t.text :notes

      t.timestamps
    end

    add_index :claims, :claim_number, unique: true
    add_index :claims, [:project_id, :claim_date]
    add_index :claims, :claim_status
    add_index :claims, :submitted_by_id
    add_foreign_key :claims, :users, column: :submitted_by_id
  end
end
