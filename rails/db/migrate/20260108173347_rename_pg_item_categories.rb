class RenamePgItemCategories < ActiveRecord::Migration[7.2]
  def up
    execute "UPDATE preliminaries_general_items SET category = 'fixed' WHERE category = 'fixed_based'"
    execute "UPDATE preliminaries_general_items SET category = 'time_based' WHERE category = 'duration_based'"
    execute "UPDATE preliminaries_general_item_templates SET category = 'fixed' WHERE category = 'fixed_based'"
    execute "UPDATE preliminaries_general_item_templates SET category = 'time_based' WHERE category = 'duration_based'"
  end

  def down
    execute "UPDATE preliminaries_general_items SET category = 'fixed_based' WHERE category = 'fixed'"
    execute "UPDATE preliminaries_general_items SET category = 'duration_based' WHERE category = 'time_based'"
    execute "UPDATE preliminaries_general_item_templates SET category = 'fixed_based' WHERE category = 'fixed'"
    execute "UPDATE preliminaries_general_item_templates SET category = 'duration_based' WHERE category = 'time_based'"
  end
end
