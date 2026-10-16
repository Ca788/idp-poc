# frozen_string_literal: true

organization = Organization.find_or_create_by!(slug: "acme") do |record|
  record.name = "Acme"
end

User.find_or_create_by!(organization: organization, email: "admin@acme.test") do |record|
  record.first_name = "Ada"
  record.last_name = "Admin"
  record.password = "changeme123"
  record.active = true
end
