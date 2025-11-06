class AddForeignKeyFromTendersToProjects < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :tenders, :projects, column: :awarded_project_id
  end
end
