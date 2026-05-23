class ExtractPhoneFieldsFromUsers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO contacts (contactable_type, contactable_id, mobile, work_phone,
        created_at, updated_at)
      SELECT 'User', id, mobile_phone, home_phone,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      WHERE mobile_phone IS NOT NULL OR home_phone IS NOT NULL
    SQL

    remove_column :users, :mobile_phone
    remove_column :users, :home_phone
  end

  def down
    add_column :users, :mobile_phone, :string
    add_column :users, :home_phone, :string
  end
end
