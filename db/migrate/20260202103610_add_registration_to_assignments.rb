class AddRegistrationToAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :assignments, :registration, :integer, default: 0
  end
end
