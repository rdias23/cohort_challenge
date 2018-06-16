class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.integer :csv_id
      t.integer :csv_order_num
      t.datetime :csv_created_at
      t.datetime :csv_updated_at
      t.integer :csv_user_id
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
