class ChangeQuantityDefaultOnPreliminariesGeneralItemTemplates < ActiveRecord::Migration[7.2]
  def change
    change_column_default :preliminaries_general_item_templates, :quantity, from: nil, to: 1.0
    change_column_default :preliminaries_general_items, :quantity, from: 0.0, to: 1.0
  end
end
