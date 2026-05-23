class ExtractCharterContactsFromSailings < ActiveRecord::Migration[8.1]
  def up
    create_table :contacts do |t|
      t.string :contactable_type, null: false
      t.integer :contactable_id, null: false
      t.string :full_name
      t.string :email_address
      t.string :work_phone
      t.string :mobile
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :postcode
      t.timestamps
    end
    add_index :contacts, [ :contactable_type, :contactable_id ]

    execute <<~SQL
      INSERT INTO contacts (contactable_type, contactable_id, full_name, email_address,
        work_phone, mobile, address1, address2, city, state, postcode,
        created_at, updated_at)
      SELECT 'Sailing', id, charter_full_name, charter_email_address,
        charter_work_phone, charter_mobile, charter_address1, charter_address2,
        charter_city, charter_state, charter_postcode,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM sailings
      WHERE charter_full_name IS NOT NULL OR charter_email_address IS NOT NULL
        OR charter_work_phone IS NOT NULL OR charter_mobile IS NOT NULL
    SQL

    remove_column :sailings, :charter_full_name
    remove_column :sailings, :charter_email_address
    remove_column :sailings, :charter_work_phone
    remove_column :sailings, :charter_mobile
    remove_column :sailings, :charter_address1
    remove_column :sailings, :charter_address2
    remove_column :sailings, :charter_city
    remove_column :sailings, :charter_state
    remove_column :sailings, :charter_postcode
  end

  def down
    add_column :sailings, :charter_full_name, :string
    add_column :sailings, :charter_email_address, :string
    add_column :sailings, :charter_work_phone, :string
    add_column :sailings, :charter_mobile, :string
    add_column :sailings, :charter_address1, :string
    add_column :sailings, :charter_address2, :string
    add_column :sailings, :charter_city, :string
    add_column :sailings, :charter_state, :string
    add_column :sailings, :charter_postcode, :string
    drop_table :contacts
  end
end
