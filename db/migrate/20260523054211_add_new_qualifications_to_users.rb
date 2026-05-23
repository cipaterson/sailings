class AddNewQualificationsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_aid_qualification, :string
    add_column :users, :first_aid_issued_on, :date
    add_column :users, :first_aid_expires_on, :date
    add_column :users, :coxswain_qualification, :string
    add_column :users, :coxswain_issued_on, :date
    add_column :users, :coxswain_expires_on, :date
    add_column :users, :food_handling_qualification, :string
    add_column :users, :food_handling_issued_on, :date
    add_column :users, :food_handling_expires_on, :date
  end
end
