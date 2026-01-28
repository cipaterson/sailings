class ChangeRatingToBeEnumInAssignments < ActiveRecord::Migration[8.1]
  def change
    change_column :assignments, :rating, :integer, default: 0
  end
end
