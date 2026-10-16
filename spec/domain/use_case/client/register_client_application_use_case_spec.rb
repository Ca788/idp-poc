# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Client::RegisterClientApplicationUseCase do
  subject(:use_case) { described_class.new }

  let(:organization) { create(:organization) }

  describe "#call" do
    it "registers a client in the organization" do
      client = use_case.call(
        organization_id: organization.id,
        name: "Portal",
        protocol: "saml",
        entity_id: "https://portal.example.test/metadata",
        acs_url: "https://portal.example.test/sso/callback"
      )

      expect(client).to be_persisted
      expect(client.organization_id).to eq(organization.id)
      expect(client.protocol).to eq("saml")
      expect(client).to be_active
    end

    it "rejects an unknown protocol" do
      expect {
        use_case.call(
          organization_id: organization.id,
          name: "Portal",
          protocol: "ldap",
          entity_id: "https://portal.example.test/metadata",
          acs_url: "https://portal.example.test/sso/callback"
        )
      }.to raise_error(Errors::UnsupportedProtocol)
    end
  end
end
