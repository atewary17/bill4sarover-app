class AddGuestFieldsToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :guest_name,    :string
    add_column :invoices, :guest_company, :string
  end
end
