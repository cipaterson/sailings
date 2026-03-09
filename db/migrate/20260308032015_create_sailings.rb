class CreateSailings < ActiveRecord::Migration[8.1]
  def change
    create_table :sailings do |t|
      t.string :purpose
      t.string :status
      t.datetime :departs_at
      t.datetime :returns_at
      t.string :ln_contact
      t.string :master
      t.text :comments

      t.timestamps
    end
  end
end
