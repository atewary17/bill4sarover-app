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

Room.create!([
  { room_number: "301", room_type: "Classic_Harmony", base_price_per_night: 4500, status: "available", organisation: org }
])