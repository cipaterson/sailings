class AddClimbingToSailingParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :sailing_participants, :climbing, :integer, default: 0
  end
end
