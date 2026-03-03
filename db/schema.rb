# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_03_03_100749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "room_id"
    t.datetime "check_in"
    t.datetime "check_out"
    t.integer "adults"
    t.integer "children"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comment"
    t.bigint "organization_id", null: false
    t.index ["customer_id"], name: "index_bookings_on_customer_id"
    t.index ["organization_id", "check_in"], name: "index_bookings_on_organization_id_and_check_in"
    t.index ["organization_id", "status"], name: "index_bookings_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_bookings_on_organization_id"
    t.index ["room_id"], name: "index_bookings_on_room_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_guest"
    t.bigint "payer_id"
    t.bigint "organization_id", null: false
    t.index ["organization_id", "phone"], name: "index_customers_on_organization_id_and_phone"
    t.index ["organization_id"], name: "index_customers_on_organization_id"
    t.index ["payer_id"], name: "index_customers_on_payer_id"
  end

  create_table "invoice_bookings", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_invoice_bookings_on_booking_id"
    t.index ["invoice_id"], name: "index_invoice_bookings_on_invoice_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.decimal "quantity", precision: 10, scale: 2
    t.decimal "unit_price", precision: 12, scale: 2
    t.string "line_discount_type"
    t.decimal "line_discount_value", precision: 12, scale: 2
    t.decimal "line_discount_amount", precision: 12, scale: 2
    t.decimal "gross_amount", precision: 14, scale: 2
    t.decimal "line_total", precision: 14, scale: 2
    t.decimal "tax_rate", precision: 5, scale: 2
    t.decimal "tax_amount", precision: 12, scale: 2
    t.string "source_type"
    t.bigint "source_id"
    t.jsonb "metadata"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["source_type", "source_id"], name: "index_invoice_items_on_source_type_and_source_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invoice_number"
    t.integer "billed_to_id"
    t.string "billed_to_type"
    t.string "billed_to_name"
    t.string "billed_to_phone"
    t.string "billed_to_email"
    t.string "company_gst_number"
    t.decimal "subtotal", precision: 10, scale: 2
    t.string "discount_type"
    t.decimal "discount_value", precision: 10, scale: 2
    t.decimal "discount_amount", precision: 10, scale: 2
    t.decimal "taxable_amount", precision: 10, scale: 2
    t.decimal "tax_rate", precision: 5, scale: 2
    t.decimal "tax_amount", precision: 10, scale: 2
    t.decimal "total_amount", precision: 10, scale: 2
    t.string "status"
    t.date "due_date"
    t.datetime "issued_at"
    t.text "notes"
    t.text "terms_and_conditions"
    t.bigint "organization_id", null: false
    t.index ["billed_to_type", "billed_to_id"], name: "index_invoices_on_billed_to_type_and_billed_to_id"
    t.index ["organization_id", "invoice_number"], name: "index_invoices_on_organization_id_and_invoice_number", unique: true
    t.index ["organization_id", "status"], name: "index_invoices_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_invoices_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "email"
    t.string "phone"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "postal_code"
    t.string "tax_id"
    t.string "logo_url"
    t.string "currency", default: "INR"
    t.string "timezone", default: "Asia/Kolkata"
    t.boolean "active", default: true
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoice_counter", default: 0, null: false
    t.index ["active"], name: "index_organizations_on_active"
    t.index ["invoice_counter"], name: "index_organizations_on_invoice_counter"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "payment_method", default: "cash"
    t.string "reference_number"
    t.text "payment_note"
    t.datetime "paid_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["paid_at"], name: "index_payments_on_paid_at"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "room_number"
    t.string "room_type"
    t.decimal "base_price_per_night"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id", "room_number"], name: "index_rooms_on_organization_id_and_room_number", unique: true
    t.index ["organization_id"], name: "index_rooms_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "role", default: 2, null: false
    t.bigint "organization_id", null: false
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "bookings", "customers"
  add_foreign_key "bookings", "organizations"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "customers", "customers", column: "payer_id"
  add_foreign_key "customers", "organizations"
  add_foreign_key "invoice_bookings", "bookings"
  add_foreign_key "invoice_bookings", "invoices"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "organizations"
  add_foreign_key "payments", "invoices"
  add_foreign_key "rooms", "organizations"
  add_foreign_key "users", "organizations"
end
