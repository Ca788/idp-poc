# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sso::Saml::Issuer do
  subject(:issuer) { described_class.new }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:client) do
    create(
      :client_application,
      organization: organization,
      protocol: "saml",
      sp_certificate: sp_certificate_pem
    )
  end
  let(:assertion) do
    Models::IdentityAssertion.new(
      subject: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      organization_id: organization.id,
      client_application_id: client.id
    )
  end

  describe "#issue" do
    it "returns an EncryptedAssertion and does not leak the email in the raw XML" do
      payload = issuer.issue(assertion: assertion, client_application: client, request_id: "_req-1")
      xml = Base64.decode64(payload)

      expect(xml).to include("EncryptedAssertion")
      expect(xml).to include('InResponseTo="_req-1"')
      expect(xml).not_to include(user.email)
    end

    it "requires the SP certificate" do
      client.update!(sp_certificate: nil)

      expect {
        issuer.issue(assertion: assertion, client_application: client)
      }.to raise_error(Errors::MissingSpCertificate)
    end

    it "rejects an expired SP certificate" do
      client.update!(sp_certificate: expired_sp_certificate_pem)

      expect {
        issuer.issue(assertion: assertion, client_application: client)
      }.to raise_error(Errors::ExpiredSpCertificate)
    end
  end
end
