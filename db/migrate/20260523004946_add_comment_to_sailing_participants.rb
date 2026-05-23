class AddCommentToSailingParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :sailing_participants, :comment, :text
  end
end
