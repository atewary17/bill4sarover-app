json.extract! customer, :id, :name, :phone, :email, :is_guest, :is_company, :created_at, :updated_at
json.url customer_url(customer, format: :json)
