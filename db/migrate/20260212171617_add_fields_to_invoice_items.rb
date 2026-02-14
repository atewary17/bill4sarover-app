class AddFieldsToInvoiceItems < ActiveRecord::Migration[7.1]
  def change
    change_table :invoice_items do |t|

      t.string  :description

      t.decimal :quantity, precision: 10, scale: 2
      t.decimal :unit_price, precision: 12, scale: 2

      t.string  :line_discount_type
      t.decimal :line_discount_value, precision: 12, scale: 2
      t.decimal :line_discount_amount, precision: 12, scale: 2

      t.decimal :gross_amount, precision: 14, scale: 2
      t.decimal :line_total, precision: 14, scale: 2

      t.decimal :tax_rate, precision: 5, scale: 2
      t.decimal :tax_amount, precision: 12, scale: 2

      t.string  :source_type
      t.bigint  :source_id

      t.jsonb   :metadata

    end

    add_index :invoice_items, [:source_type, :source_id]
  end
end
