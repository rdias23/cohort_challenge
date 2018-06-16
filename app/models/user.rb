class User < ApplicationRecord
	require 'csv'

	has_many :orders

  def self.import(file)
  	CSV.foreach(file.path, headers: true) do |row|
      attr_hash = row.to_hash.each_with_object({}) {|(k,v),o| o[("csv_" + k).to_sym] = v }

      attr_hash[:csv_created_at] = DateTime.strptime(attr_hash[:csv_created_at], '%m/%d/%Y %H:%M:%S')
      attr_hash[:csv_updated_at] = DateTime.strptime(attr_hash[:csv_updated_at], '%m/%d/%Y %H:%M:%S')
      attr_hash[:csv_id] = attr_hash[:csv_id].to_i

      existing_user = User.find_by_csv_id(attr_hash[:csv_id])
      existing_orders = Order.where(:csv_user_id => attr_hash[:csv_id])

      unless existing_user
        user = User.new
        user.assign_attributes(attr_hash)

        user.orders << existing_orders if existing_orders.length > 0
        user.save!
      end

      if existing_user && existing_orders && ((existing_orders - existing_user.orders).length != 0)
        existing_user.orders << (existing_orders - existing_user.orders)
        existing_user.save!
      end

  	end
  end

end
