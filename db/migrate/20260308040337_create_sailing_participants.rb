class CreateSailingParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :sailing_participants do |t|
      t.references :sailing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end

    add_index :sailing_participants, [ :sailing_id, :user_id ], unique: true
  end
end
