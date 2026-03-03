# # org = Organisation.find_or_create_by!(name: "Oracle PVT LTD") do |o|
# #     o.slug     ="oracle-hotel"
# #     o.tax_id   = "27AABCU9603R1ZX"   
# #     o.address  = "Mumbai, Maharashtra, India"
# #     o.status   = :active
# # end

# # puts "✅ Organisation: #{org.name} (ID: #{org.id})"

# # # ── User ──────────────────────────────────────────────────
# # user = User.find_or_create_by!(email: "atewary17@gmail.com") do |u|
# #   u.name = "Anish Tewary"
# #   u.password   = "asansol8"
# #   u.role         = :super_admin
# #   u.organisation = org
# # end

# # puts "✅ User: #{user.full_name} <#{user.email}> — #{user.role} @ #{org.name}"

# # puts "\n✅ Seeding complete!"

# # Room.create!([
# #   { room_number: "301", room_type: "Classic_Harmony", base_price_per_night: 4500, status: "available", organisation: org }
# # ])


# # db/seeds.rb

# # 1. FIRST: Create Organization (parent for everything)
# org = Organization.find_or_create_by!(name: "Oracle PVT LTD") do |o|
#   o.slug      = "oracle-hotel"
#   o.tax_id    = "27AABCU9603R1ZX"   
#   o.address   = "Mumbai, Maharashtra, India"
#   o.email      = "info@oraclehotel.com"
#   o.phone     = "+91-9876543210"
# end

# puts "✅ Organization: #{org.name} (ID: #{org.id})"

# # 2. Create Rooms (requires organization_id)
# Room.create!([
#   { room_number: "301", room_type: "Classic_Harmony", base_price_per_night: 4500, status: "available", organization_id: org.id },
#   { room_number: "302", room_type: "Regal_Harmony", base_price_per_night: 3500, status: "available", organization_id: org.id },
#   { room_number: "303", room_type: "Regal_Harmony", base_price_per_night: 4000, status: "available", organization_id: org.id },
#   { room_number: "304", room_type: "Classic_Residence", base_price_per_night: 2500, status: "available", organization_id: org.id },
#   { room_number: "401", room_type: "Classic_Harmony", base_price_per_night: 4500, status: "available", organization_id: org.id },
#   { room_number: "402", room_type: "Regal_Harmony", base_price_per_night: 3500, status: "available", organization_id: org.id },
#   { room_number: "403", room_type: "Regal_Harmony", base_price_per_night: 4000, status: "available", organization_id: org.id },
#   { room_number: "404", room_type: "Classic_Residence", base_price_per_night: 2500, status: "available", organization_id: org.id },
#   { room_number: "200", room_type: "Banquet", base_price_per_night: 40000, status: "available", organization_id: org.id }
# ])

# puts "✅ 9 Rooms created for #{org.name}"

# # 3. Create Super Admin User (requires organization_id)
# user = User.find_or_create_by!(email: "atewary17@gmail.com") do |u|
#   u.name       = "Anish Tewary"
#   u.password   = "asansol8"
#   u.role       = :super_admin
#   u.organization_id = org.id  # Fixed: use organization_id, not organisation
# end

# puts "✅ Super Admin: #{user.name} <#{user.email}> — #{user.role} @ #{org.name}"

# # 4. Optional: Sample Customer
# # Customer.find_or_create_by!(phone: "+91-9876543210", organization_id: org.id) do |c|
# #   c.name     = "Sample Guest"
# #   c.email    = "guest@oraclehotel.com"
# #   c.is_guest = true
# # end

# # puts "✅ Sample Customer created"

# puts "\n✅ Seeding complete! App ready at #{org.name}"
