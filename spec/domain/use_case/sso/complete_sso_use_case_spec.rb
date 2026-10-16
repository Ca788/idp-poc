# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Sso::CompleteSsoUseCase do
  subject(:use_case) { described_class.new(issuer_factory: issuer_factory) }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:client) { create(:client_application, organization: organization, protocol: "saml") }
  let(:issuer) { instance_double(Sso::Saml::Issuer, issue: "SAML-PAYLOAD") }
  let(:issuer_factory) { class_double(Sso::IssuerFactory, build: issuer) }

  describe "#call" do
    it "issues a protocol payload without the use case knowing SAML" do
      result = use_case.call(
        organization_id: organization.id,
        user_id: user.id,
        client_application_id: client.id,
        relay_state: "state-1",
        request_id: "_req-1"
      )

      expect(issuer_factory).to have_received(:build).with("saml")
      expect(issuer).to have_received(:issue).with(
        assertion: an_instance_of(Models::IdentityAssertion),
        client_application: client,
        request_id: "_req-1"
      )
      expect(result.payload).to eq("SAML-PAYLOAD")
      expect(result.acs_url).to eq(client.acs_url)
      expect(result.relay_state).to eq("state-1")
      expect(result.protocol).to eq("saml")
    end
  end
end
