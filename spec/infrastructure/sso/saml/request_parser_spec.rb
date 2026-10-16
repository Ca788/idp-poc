# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sso::Saml::RequestParser do
  subject(:parser) { described_class.new }

  let(:entity_id) { "https://app.example.test/sp" }
  let(:acs_url) { "https://app.example.test/sso/callback" }

  describe "#parse" do
    it "extracts issuer, ACS, request id and destination" do
      parsed = parser.parse(deflated_saml_request(entity_id: entity_id, acs_url: acs_url, request_id: "_req-abc"))

      expect(parsed.entity_id).to eq(entity_id)
      expect(parsed.acs_url).to eq(acs_url)
      expect(parsed.request_id).to eq("_req-abc")
      expect(parsed.destination).to eq(SamlIdp.config.single_service_post_location)
      expect(parsed.force_authn).to be(false)
      expect(parsed.is_passive).to be(false)
    end

    it "rejects a Destination that is not the IdP SSO URL" do
      raw = deflated_saml_request(
        entity_id: entity_id,
        acs_url: acs_url,
        destination: "https://evil.example.test/saml"
      )

      expect { parser.parse(raw) }.to raise_error(Errors::InvalidSamlRequest)
    end

    it "rejects an IssueInstant outside the allowed window" do
      raw = deflated_saml_request(
        entity_id: entity_id,
        acs_url: acs_url,
        issue_instant: 1.hour.ago
      )

      expect { parser.parse(raw) }.to raise_error(Errors::InvalidSamlRequest)
    end

    it "rejects ForceAuthn combined with IsPassive" do
      raw = deflated_saml_request(
        entity_id: entity_id,
        acs_url: acs_url,
        force_authn: true,
        is_passive: true
      )

      expect { parser.parse(raw) }.to raise_error(Errors::InvalidSamlRequest)
    end
  end

  describe ".claim_request_id!" do
    it "rejects a replayed request id" do
      described_class.claim_request_id!("_req-replay")

      expect {
        described_class.claim_request_id!("_req-replay")
      }.to raise_error(Errors::InvalidSamlRequest)
    end
  end

  describe "#verify_query_signature!" do
    it "accepts a valid SHA-256 query signature" do
      raw = deflated_saml_request(entity_id: entity_id, acs_url: acs_url)
      sig_alg = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
      signed = "SAMLRequest=#{CGI.escape(raw)}&SigAlg=#{CGI.escape(sig_alg)}"
      key = OpenSSL::PKey::RSA.new(sp_private_key_pem)
      signature = Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, signed))

      expect {
        parser.verify_query_signature!(
          raw_saml_request: raw,
          signature: signature,
          sig_algorithm: sig_alg,
          relay_state: nil,
          certificate: sp_certificate_pem
        )
      }.not_to raise_error
    end

    it "rejects SHA-1 signatures" do
      expect {
        parser.verify_query_signature!(
          raw_saml_request: "abc",
          signature: "c2ln",
          sig_algorithm: "http://www.w3.org/2000/09/xmldsig#sha1",
          relay_state: nil,
          certificate: sp_certificate_pem
        )
      }.to raise_error(Errors::InvalidSamlRequest)
    end
  end
end
