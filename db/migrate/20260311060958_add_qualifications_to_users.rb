class AddQualificationsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ess_qualification, :string
    add_column :users, :ess_issued_on, :date
    add_column :users, :ess_expires_on, :date
    add_column :users, :med_qualification, :string
    add_column :users, :med_issued_on, :date
    add_column :users, :med_expires_on, :date
    add_column :users, :wwvp_qualification, :string
    add_column :users, :wwvp_issued_on, :date
    add_column :users, :wwvp_expires_on, :date
  end
end
