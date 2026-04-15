class AddPriorityToMaintenanceTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :maintenance_tasks, :priority, :string
  end
end
