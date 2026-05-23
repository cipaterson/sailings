class AddContactTypeToContacts < ActiveRecord::Migration[8.1]
  def up
    add_column :contacts, :contact_type, :string

    execute "UPDATE contacts SET contact_type = 'contact'         WHERE contactable_type = 'User'"
    execute "UPDATE contacts SET contact_type = 'charter_contact' WHERE contactable_type = 'Sailing'"
  end

  def down
    remove_column :contacts, :contact_type
  end
end
