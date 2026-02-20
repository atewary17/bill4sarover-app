class AddRoleEnumToUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :role, :string if column_exists?(:users, :role)
    
    add_column :users, :role, :integer, default: 2, null: false
    add_index :users, :role
  end
end