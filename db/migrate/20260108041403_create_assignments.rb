class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments do |t|
      t.belongs_to :sailing, null: false, foreign_key: true
      t.belongs_to :users, null: false, foreign_key: true
      t.string :rating

      t.timestamps
    end
  end
end
