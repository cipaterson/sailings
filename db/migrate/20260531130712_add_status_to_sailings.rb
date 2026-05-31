class AddStatusToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :status, :string, default: "draft"
  end
end
