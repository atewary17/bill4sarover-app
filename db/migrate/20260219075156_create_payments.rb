class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :payment_method, default: "cash"
      t.string :reference_number
      t.text :payment_note
      t.datetime :paid_at, null: false

      t.timestamps
    end

    add_index :payments, :paid_at
  end
end