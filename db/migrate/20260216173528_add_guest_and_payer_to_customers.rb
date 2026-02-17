class AddGuestAndPayerToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :is_guest, :boolean
    add_reference :customers, :payer, foreign_key: { to_table: :customers }, index: true
  end
end
