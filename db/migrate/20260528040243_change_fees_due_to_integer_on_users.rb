class ChangeFeesDueToIntegerOnUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :fees_due_year, :integer

    User.reset_column_information
    User.where.not(fees_due: nil).find_each do |user|
      user.update_column(:fees_due_year, user.fees_due.year)
    end

    remove_column :users, :fees_due
    rename_column :users, :fees_due_year, :fees_due
  end

  def down
    add_column :users, :fees_due_old, :date

    User.reset_column_information
    User.where.not(fees_due: nil).find_each do |user|
      user.update_column(:fees_due_old, Date.new(user.fees_due, 6, 30))
    end

    remove_column :users, :fees_due
    rename_column :users, :fees_due_old, :fees_due
  end
end
