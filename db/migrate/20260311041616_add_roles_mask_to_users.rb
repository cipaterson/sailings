class AddRolesMaskToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :roles_mask, :integer, default: 0, null: false
  end
end
