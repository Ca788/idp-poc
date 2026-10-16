# frozen_string_literal: true

module Sso
  module Saml
    class Issuer < Sso::Issuer
      include SamlIdp::Controller

      def issue(assertion:, client_application:, request_id: nil)
        raise Errors::MissingSpCertificate if client_application.sp_certificate.blank?

        cert = OpenSSL::X509::Certificate.new(client_application.sp_certificate)
        now = Time.now.utc
        raise Errors::ExpiredSpCertificate unless now.between?(cert.not_before, cert.not_after)

        @in_response_to = request_id
        self.algorithm = :sha256
        encode_authn_response(
          Principal.new(
            id: assertion.subject,
            email: assertion.email,
            first_name: assertion.first_name,
            last_name: assertion.last_name
          ),
          audience_uri: client_application.entity_id,
          acs_url: client_application.acs_url,
          signed_message: true,
          encryption: {
            cert: cert,
            block_encryption: "aes256-cbc",
            key_transport: "rsa-oaep-mgf1p"
          }
        )
      end

      def saml_request_id
        @in_response_to
      end
    end
  end
end
