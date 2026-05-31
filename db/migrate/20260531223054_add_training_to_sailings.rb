class AddTrainingToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :training, :string
  end
end
