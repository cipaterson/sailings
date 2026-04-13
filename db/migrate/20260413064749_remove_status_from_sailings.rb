class RemoveStatusFromSailings < ActiveRecord::Migration[8.1]
  def change
    remove_column :sailings, :status, :string
  end
end
