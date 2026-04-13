class AddStateAndFixedNoteToMaintenanceTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :maintenance_tasks, :state, :string
    add_column :maintenance_tasks, :fixed_note, :text
  end
end
