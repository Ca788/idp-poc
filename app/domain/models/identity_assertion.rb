# frozen_string_literal: true

module Models
  IdentityAssertion = Struct.new(
    :subject,
    :email,
    :first_name,
    :last_name,
    :organization_id,
    :client_application_id,
    keyword_init: true
  )
end
