class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :email
      t.string :phone
      t.string :address
      t.string :city
      t.string :state
      t.string :country
      t.string :postal_code
      t.string :tax_id # GST/Tax number
      t.string :logo_url
      t.string :currency, default: 'INR'
      t.string :timezone, default: 'Asia/Kolkata'
      t.boolean :active, default: true
      t.jsonb :settings, default: {}
      
      t.timestamps
    end

    add_index :organizations, :slug, unique: true
    add_index :organizations, :active
  end
end