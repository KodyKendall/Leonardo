class RemoveFlowsRelatedTables < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :flow_metrics, :flows
    remove_foreign_key :activities, :flows
    remove_foreign_key :flows, :users
    drop_table :flow_metrics
    drop_table :activities
    drop_table :flows
  end
end
