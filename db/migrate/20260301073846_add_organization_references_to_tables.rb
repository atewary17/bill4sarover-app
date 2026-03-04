class AddOrganizationReferencesToTables < ActiveRecord::Migration[7.1]
  def change
    # Add organization_id columns as NULLABLE first
    add_reference :users, :organization, foreign_key: true, null: true
    add_reference :customers, :organization, foreign_key: true, null: true
    add_reference :rooms, :organization, foreign_key: true, null: true
    add_reference :bookings, :organization, foreign_key: true, null: true
    add_reference :invoices, :organization, foreign_key: true, null: true
  end
end