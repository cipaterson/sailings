class CreateAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :assignments, primary_key: [ :sailing_id, :user_id ] do |t|
       t.belongs_to :sailing, null: false, foreign_key: true
       t.belongs_to :user, null: false, foreign_key: true
       t.integer :rating, default: 0

       t.timestamps
    end
  end
end
