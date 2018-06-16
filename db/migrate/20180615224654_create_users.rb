class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.integer :csv_id
      t.datetime :csv_created_at
      t.datetime :csv_updated_at

      t.timestamps
    end
  end
end
