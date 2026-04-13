class AddAttendedToSailingParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :sailing_participants, :attended, :integer
  end
end
