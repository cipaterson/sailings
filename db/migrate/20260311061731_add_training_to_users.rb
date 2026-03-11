class AddTrainingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :knots_on, :date
    add_column :users, :marine_safety_refresher_on, :date
  end
end
