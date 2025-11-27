json.extract! client, :id, :business_name, :contact_name, :contact_email, :created_at, :updated_at
json.url client_url(client, format: :json)
