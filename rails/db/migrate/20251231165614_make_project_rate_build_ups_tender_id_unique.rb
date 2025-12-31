class MakeProjectRateBuildUpsTenderIdUnique < ActiveRecord::Migration[7.2]
  def change
    remove_index :project_rate_build_ups, :tender_id
    add_index :project_rate_build_ups, :tender_id, unique: true
  end
end
