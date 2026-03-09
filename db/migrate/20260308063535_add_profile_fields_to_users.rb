class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :mobile_phone, :string
    add_column :users, :home_phone, :string
    add_column :users, :birth_date, :date
    add_column :users, :occupation, :string
    add_column :users, :membership_type, :string
    add_column :users, :sailing_class, :string
    add_column :users, :sit_date, :date
  end
end
