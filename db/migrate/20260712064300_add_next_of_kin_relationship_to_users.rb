class AddNextOfKinRelationshipToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :next_of_kin_relationship, :string
  end
end
