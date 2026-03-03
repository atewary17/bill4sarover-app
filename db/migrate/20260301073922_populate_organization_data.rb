class PopulateOrganizationData < ActiveRecord::Migration[7.1]
  def up
    # Create default organization
    org = Organization.create!(
      name: 'Sarover Hotel',
      slug: 'sarover-hotel',
      email: 'admin@sarover.com',
      phone: '+91-1234567890',
      address: 'Hotel Address',
      city: 'Kolkata',
      state: 'West Bengal',
      country: 'India',
      currency: 'INR',
      timezone: 'Asia/Kolkata',
      active: true,
      settings: {
        invoice_prefix: 'SAR',
        default_tax_rate: 18.0
      }
    )
    
    puts "✅ Created organization: #{org.name} (ID: #{org.id})"
    
    # Update all existing records
    User.update_all(organization_id: org.id)
    Customer.update_all(organization_id: org.id)
    Room.update_all(organization_id: org.id)
    Booking.update_all(organization_id: org.id)
    Invoice.update_all(organization_id: org.id)
    
    puts "✅ Updated #{User.count} users"
    puts "✅ Updated #{Customer.count} customers"
    puts "✅ Updated #{Room.count} rooms"
    puts "✅ Updated #{Booking.count} bookings"
    puts "✅ Updated #{Invoice.count} invoices"
  end
  
  def down
    # Revert all to nil
    User.update_all(organization_id: nil)
    Customer.update_all(organization_id: nil)
    Room.update_all(organization_id: nil)
    Booking.update_all(organization_id: nil)
    Invoice.update_all(organization_id: nil)
    
    # Delete the organization
    Organization.find_by(slug: 'sarover-hotel')&.destroy
  end
end