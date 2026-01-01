class AddFlagsAndTemplateToPreliminariesGeneralItems < ActiveRecord::Migration[7.2]
  def change
    add_column :preliminaries_general_items, :is_crane, :boolean, default: false, null: false
    add_column :preliminaries_general_items, :is_access_equipment, :boolean, default: false, null: false
    add_reference :preliminaries_general_items, :preliminaries_general_item_template, null: true, foreign_key: true, index: { name: 'index_pg_items_on_pg_template_id' }
  end
end
