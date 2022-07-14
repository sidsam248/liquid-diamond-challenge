class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.string :name
      t.float :weight
      t.float :price
      t.string :state

      t.timestamps
    end
  end
end
