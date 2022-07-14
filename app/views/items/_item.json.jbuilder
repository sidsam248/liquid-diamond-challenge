json.extract! item, :id, :name, :weight, :total_price, :price_per_unit, :state, :created_at, :updated_at
json.url item_url(item, format: :json)
