class UpdateUserRoleDefault < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :role, from: "project_manager", to: "quantity_surveyor"
    
    reversible do |dir|
      dir.up do
        User.where(role: "project_manager").update_all(role: "quantity_surveyor")
      end
    end
  end
end
