class AddInvoiceCounterToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :invoice_counter, :integer, default: 0, null: false
    add_index :organizations, :invoice_counter
  end
end