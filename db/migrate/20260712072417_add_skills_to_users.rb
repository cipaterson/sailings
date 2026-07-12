class AddSkillsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :skills_mask, :integer, default: 0, null: false
    add_column :users, :special_skills, :text
  end
end
