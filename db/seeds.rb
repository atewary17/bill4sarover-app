Room.create!([
  { room_number: "301", room_type: "Classic_Harmony", base_price_per_night: 4500, status: "available" },
  { room_number: "302", room_type: "Regal_Harmony", base_price_per_night: 3500, status: "available" },
  { room_number: "303", room_type: "Regal_Harmony", base_price_per_night: 4000, status: "available" },
  { room_number: "304", room_type: "Classic_Residence", base_price_per_night: 2500, status: "available" },
  { room_number: "401", room_type: "Classic_Harmony", base_price_per_night: 4500, status: "available" },
  { room_number: "402", room_type: "Regal_Harmony", base_price_per_night: 3500, status: "available" },
  { room_number: "403", room_type: "Regal_Harmony", base_price_per_night: 4000, status: "available" },
  { room_number: "404", room_type: "Classic_Residence", base_price_per_night: 2500, status: "available" },
  { room_number: "200", room_type: "Banquet", base_price_per_night: 40000, status: "available" }
])

org = Organisation.find_or_create_by!(name: "Oracle PVT LTD") do |o|
    o.slug     ="oracle-hotel"
    o.tax_id   = "27AABCU9603R1ZX"   
    o.address  = "Mumbai, Maharashtra, India"
    o.status   = :active
end

puts "✅ Organisation: #{org.name} (ID: #{org.id})"

# ── User ──────────────────────────────────────────────────
user = User.find_or_create_by!(email: "atewary17@gmail.com") do |u|
  u.name = "Anish Tewary"
  u.password   = "asansol8"
  u.role         = :super_admin
  u.organisation = org
end

puts "✅ User: #{user.full_name} <#{user.email}> — #{user.role} @ #{org.name}"

puts "\n✅ Seeding complete!"
