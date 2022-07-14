class AddNewPriceFieldsToItems < ActiveRecord::Migration[5.1]
  def change
  	add_column :items, :price_per_unit, :float
  	rename_column :items, :price, :total_price
  end
end
