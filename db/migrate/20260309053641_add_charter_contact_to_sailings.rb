class AddCharterContactToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :charter_full_name, :string
    add_column :sailings, :charter_email_address, :string
    add_column :sailings, :charter_work_phone, :string
    add_column :sailings, :charter_mobile, :string
    add_column :sailings, :charter_address1, :string
    add_column :sailings, :charter_address2, :string
    add_column :sailings, :charter_city, :string
    add_column :sailings, :charter_state, :string
    add_column :sailings, :charter_postcode, :string
  end
end
