class ChangeCharterStateDefaultToTbc < ActiveRecord::Migration[8.1]
  def change
    change_column_default :sailings, :charter_state, from: nil, to: "TBC"
  end
end
