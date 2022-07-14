class Item < ActiveRecord::Base

	validates :name,  presence: true
	# An item will either be in listed OR delisted state. 
	# When a file is uploaded and a record is created/ updated, the record must be in 'listed' state
	# If the user syncronizes their inventory then any item that's not present in the file must be moved to "delisted" state
	STATE_OPTIONS = %w(delisted listed)
  	validates :state, :inclusion => {:in => STATE_OPTIONS, message: "Expecting value of state is in #{STATE_OPTIONS} but got '%{value}'."}
  	validates :weight, numericality: true
  	validates :total_price, numericality: true
  	validates :price_per_unit, numericality: true

	# Use Case - Item.import(file)
	# Description - Used to import items from an csv file and save that into database
	# @param [file] file <file should be in csv format>
	# @return - (1 for success, 0 for error)
	def self.import(file)
		return 0 if file.blank?

		# store ids of items that exist
		current_inventory = []

		# TODO: 
		# 1. Sample file used here has three columns with following headers
		# 	- Name
		# 	- Weight
		# 	- Price
		# 	Currently it supports single price column and it represents (total price of item)
		# 	As a user, I should be able to upload a file with "Price per unit" (Total Price/ weight) OR "Total Price" OR both and it should save the record's price accordingly
		# 2. As a user, I should be able to update a record's price or weight by reuploading the file post correction. 
		# 3. As a user, I should be able to syncronize my inventory OR upload just the updates (make use of states)

		# === New changes ===


		# Updated Sample file has four columns with following headers
		# - Name
		# - Weight
		# - Price Per unit
		# - Total Price


		CSV.foreach(file.path, headers: true) do |row|
			row_hash = row.to_hash

			return 0 if !row_hash.key?("price_per_unit") || !row_hash.key?("total_price")

			@item = Item.where(:name => row_hash["name"]).first

			p row_hash

			# Handling update of Total Price and Price per unit. Calculate as required if either of their values does not exist.
			if row_hash["price_per_unit"] == nil || row_hash["price_per_unit"].to_f == 0

				price_per_unit = row_hash["total_price"].to_f / row_hash["weight"].to_f

				row_hash["price_per_unit"] = price_per_unit

			elsif row_hash["total_price"] == nil || row_hash["total_price"].to_f == 0

				total_price = row_hash["price_per_unit"].to_f * row_hash["weight"].to_f

				row_hash["total_price"] = total_price
			end

			row_hash["state"] = "listed"

			# If item exists, update the record otherwise create a new record.
			if @item
				@item.update_attributes(row_hash)
			else
				@item = Item.create! row_hash
			end

			# store id of current item
			current_inventory << @item.id if @item
		end

		# Handling sync of current inventory. Changing items that dont exist to the "delisted" state.
		@items = Item.where("id NOT IN (?)", current_inventory)
		@items.update_all(:state => "delisted")

		return 1
	end

	# Use Case - Item.search(params)
	# Description - Used to search for items from the database based on their state.
	# @param [state] - Valid options are (All, Listed, Delisted)
	# @return nil
	def self.search(params)
		@items = self.all
		state = params[:state]

		return @items if state == nil || state == "All"
		
		@items = @items.where(:state => state)
		
		return @items
	end
end
