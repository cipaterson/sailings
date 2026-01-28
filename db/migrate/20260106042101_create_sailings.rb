class CreateSailings < ActiveRecord::Migration[8.1]
  def change
    create_table :sailings do |t|
      t.string :name

      t.timestamps
    end
  end
end
