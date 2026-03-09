class AddCharterFieldsToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :charterer, :string
    add_column :sailings, :passenger_count, :integer
    add_column :sailings, :additional_details, :text
    add_column :sailings, :engineer, :string
  end
end
