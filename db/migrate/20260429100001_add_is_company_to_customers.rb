class AddIsCompanyToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :customers, :is_company, :boolean, default: false, null: false
  end
end
