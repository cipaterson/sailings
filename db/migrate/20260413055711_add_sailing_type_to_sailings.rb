class AddSailingTypeToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :sailing_type, :string
  end
end
