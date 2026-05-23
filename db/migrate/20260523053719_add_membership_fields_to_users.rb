class AddMembershipFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :fees_due, :date
    add_column :users, :days_sailed, :integer
    add_column :users, :date_joined, :date
    add_column :users, :last_sailed, :date
    add_column :users, :fees_paid, :date
    add_column :users, :rcpt_number, :string
    add_column :users, :sit2_date, :date
  end
end
