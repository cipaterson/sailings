class AddCharterStateToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :charter_state, :string
  end
end
