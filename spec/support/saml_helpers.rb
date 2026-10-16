# frozen_string_literal: true

module SamlHelpers
  def deflated_saml_request(
    entity_id:,
    acs_url:,
    request_id: "_req-1",
    destination: SamlIdp.config.single_service_post_location,
    issue_instant: Time.now.utc,
    force_authn: false,
    is_passive: false
  )
    attrs = [
      %(ID="#{request_id}"),
      'Version="2.0"',
      %(IssueInstant="#{issue_instant.utc.iso8601}"),
      %(AssertionConsumerServiceURL="#{acs_url}")
    ]
    attrs << %(Destination="#{destination}") if destination.present?
    attrs << 'ForceAuthn="true"' if force_authn
    attrs << 'IsPassive="true"' if is_passive

    xml = <<~XML
      <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
        #{attrs.join(" ")}>
        <saml:Issuer>#{entity_id}</saml:Issuer>
      </samlp:AuthnRequest>
    XML

    deflater = Zlib::Deflate.new(Zlib::BEST_COMPRESSION, -Zlib::MAX_WBITS)
    deflated = deflater.deflate(xml, Zlib::FINISH)
    deflater.close
    Base64.strict_encode64(deflated)
  end

  def sp_certificate_pem
    SamlHelpers.sp_pair[:certificate]
  end

  def sp_private_key_pem
    SamlHelpers.sp_pair[:private_key]
  end

  def expired_sp_certificate_pem
    rsa = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=sp-expired")
    cert.public_key = rsa.public_key
    cert.not_before = Time.now.utc - (86_400 * 10)
    cert.not_after = Time.now.utc - 86_400
    cert.sign(rsa, OpenSSL::Digest::SHA256.new)
    cert.to_pem
  end

  def self.sp_pair
    @sp_pair ||= generate_pair("sp-test")
  end

  def self.generate_pair(common_name)
    rsa = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 1
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=#{common_name}")
    cert.public_key = rsa.public_key
    cert.not_before = Time.now.utc - 86_400
    cert.not_after = Time.now.utc + (86_400 * 3650)
    cert.sign(rsa, OpenSSL::Digest::SHA256.new)

    { certificate: cert.to_pem, private_key: rsa.to_pem }
  end
end

RSpec.configure do |config|
  config.include SamlHelpers
end
