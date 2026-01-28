class AddDetailsToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :start_date, :date
    add_column :sailings, :start_time, :time
    add_column :sailings, :return_date, :date
    add_column :sailings, :return_time, :time
    add_column :sailings, :comments, :string
  end
end
