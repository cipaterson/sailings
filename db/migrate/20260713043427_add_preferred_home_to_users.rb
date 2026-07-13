class AddPreferredHomeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :preferred_home, :string
  end
end
