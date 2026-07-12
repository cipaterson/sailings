class AddCommentsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :comments, :text
  end
end
