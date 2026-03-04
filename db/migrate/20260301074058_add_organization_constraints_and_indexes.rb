class AddOrganizationConstraintsAndIndexes < ActiveRecord::Migration[7.1]
  def change
    # Make organization_id NOT NULL
    change_column_null :users, :organization_id, false
    change_column_null :customers, :organization_id, false
    change_column_null :rooms, :organization_id, false
    change_column_null :bookings, :organization_id, false
    change_column_null :invoices, :organization_id, false
    
    # Add composite indexes for users
    add_index :users, [:organization_id, :email], unique: true
    remove_index :users, :email if index_exists?(:users, :email)
    
    # Add indexes for customers
    add_index :customers, [:organization_id, :phone]
    
    # Add indexes for rooms
    add_index :rooms, [:organization_id, :room_number], unique: true
    
    # Add indexes for bookings
    add_index :bookings, [:organization_id, :status]
    add_index :bookings, [:organization_id, :check_in]
    
    # Add indexes for invoices
    add_index :invoices, [:organization_id, :status]
    add_index :invoices, [:organization_id, :invoice_number], unique: true
    remove_index :invoices, :invoice_number if index_exists?(:invoices, :invoice_number)
  end
end