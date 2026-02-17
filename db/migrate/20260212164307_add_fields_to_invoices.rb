class AddFieldsToInvoices < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :invoice_number, :string

    add_column :invoices, :billed_to_id, :integer
    add_column :invoices, :billed_to_type, :string

    add_column :invoices, :billed_to_name, :string
    add_column :invoices, :billed_to_phone, :string
    add_column :invoices, :billed_to_email, :string

    add_column :invoices, :company_gst_number, :string

    add_column :invoices, :subtotal, :decimal, precision: 10, scale: 2
    add_column :invoices, :discount_type, :string
    add_column :invoices, :discount_value, :decimal, precision: 10, scale: 2
    add_column :invoices, :discount_amount, :decimal, precision: 10, scale: 2

    add_column :invoices, :taxable_amount, :decimal, precision: 10, scale: 2
    add_column :invoices, :tax_rate, :decimal, precision: 5, scale: 2
    add_column :invoices, :tax_amount, :decimal, precision: 10, scale: 2

    add_column :invoices, :total_amount, :decimal, precision: 10, scale: 2

    add_column :invoices, :status, :string

    add_column :invoices, :due_date, :date
    add_column :invoices, :issued_at, :datetime

    add_column :invoices, :notes, :text
    add_column :invoices, :terms_and_conditions, :text

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, [:billed_to_type, :billed_to_id]
  end
end
