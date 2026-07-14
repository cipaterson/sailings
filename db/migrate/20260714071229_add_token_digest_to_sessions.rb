class AddTokenDigestToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :token_digest, :string
    add_index :sessions, :token_digest, unique: true
  end
end
