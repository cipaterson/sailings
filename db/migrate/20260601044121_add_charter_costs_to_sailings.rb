class AddCharterCostsToSailings < ActiveRecord::Migration[8.1]
  def change
    add_column :sailings, :quoted_cost_cents, :integer
    add_column :sailings, :deposit_invoice, :string
    add_column :sailings, :deposit_invoice_date, :date
    add_column :sailings, :deposit_cents, :integer
    add_column :sailings, :deposit_receipt_no, :string
    add_column :sailings, :final_amount_cents, :integer
    add_column :sailings, :invoice_date, :date
    add_column :sailings, :final_invoice, :string
    add_column :sailings, :date_paid, :date
    add_column :sailings, :receipt_no, :string
  end
end
