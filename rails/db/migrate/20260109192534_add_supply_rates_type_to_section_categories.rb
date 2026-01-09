class AddSupplyRatesTypeToSectionCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :section_categories, :supply_rates_type, :string
  end
end
