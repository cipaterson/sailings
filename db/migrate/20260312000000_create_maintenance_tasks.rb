class CreateMaintenanceTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_tasks do |t|
      t.string :problem_description, null: false
      t.datetime :date_reported, null: false
      t.datetime :date_fixed
      t.string :who_reported, null: false
      t.string :who_fixed
      t.text :comments

      t.timestamps
    end
  end
end
