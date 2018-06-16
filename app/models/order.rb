class Order < ApplicationRecord
	require 'csv'

  belongs_to :user, optional: true

  def self.import(file)
  	CSV.foreach(file.path, headers: true) do |row|
      attr_hash = row.to_hash.each_with_object({}) {|(k,v),o| o[("csv_" + k).to_sym] = v }

      attr_hash[:csv_created_at] = DateTime.strptime(attr_hash[:csv_created_at], '%m/%d/%Y %H:%M:%S')
      attr_hash[:csv_updated_at] = DateTime.strptime(attr_hash[:csv_updated_at], '%m/%d/%Y %H:%M:%S')
      attr_hash[:csv_id] = attr_hash[:csv_id].to_i
      attr_hash[:csv_user_id] = attr_hash[:csv_user_id].to_i
      attr_hash[:csv_order_num] = attr_hash[:csv_order_num].to_i

      user = User.find_by_csv_id(attr_hash[:csv_user_id])
      existing_order = Order.find_by_csv_id(attr_hash[:csv_id])

      unless existing_order
        order = Order.new
        order.assign_attributes(attr_hash)
        order.user = user if user

        order.save!
      end

      if existing_order && user && (existing_order.user == nil)
      	existing_order.user = user

      	existing_order.save!
      end
  	end
  end
end
