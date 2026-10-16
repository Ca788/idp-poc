# frozen_string_literal: true

SamlIdp.configure do |config|
  base = ENV.fetch("IDP_BASE_URL", "http://localhost:3000")
  if Rails.env.production? && !base.start_with?("https://")
    raise "IDP_BASE_URL must use https in production"
  end

  config.x509_certificate = -> { Sso::IdpKeyMaterial.certificate }
  config.secret_key = -> { Sso::IdpKeyMaterial.private_key }
  config.algorithm = :sha256
  config.base_saml_location = "#{base}/saml"
  config.entity_id = "#{base}/saml/metadata"
  config.single_service_post_location = "#{base}/saml/auth"
  config.single_service_redirect_location = "#{base}/saml/auth"
  config.single_logout_service_post_location = nil
  config.single_logout_service_redirect_location = nil
  config.session_expiry = 12.hours.to_i
  config.name_id.formats = {
    email_address: ->(principal) { principal.email }
  }
  config.attributes = {
    "email" => { getter: :email },
    "firstName" => { getter: :first_name },
    "lastName" => { getter: :last_name },
    "sub" => { getter: :id }
  }
end
