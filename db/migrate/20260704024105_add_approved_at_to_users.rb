class AddApprovedAtToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :approved_at, :datetime

    # Existing users predate the approval workflow — treat them as already approved
    # so they keep logging in. Backfill with their creation time.
    execute "UPDATE users SET approved_at = created_at WHERE approved_at IS NULL"
  end

  def down
    remove_column :users, :approved_at
  end
end
