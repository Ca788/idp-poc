# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Sso::FindClientApplicationUseCase do
  subject(:use_case) { described_class.new }

  let(:organization) { create(:organization) }
  let(:client) { create(:client_application, organization: organization) }

  describe "#call" do
    it "returns the client in the organization" do
      result = use_case.call(
        organization_id: organization.id,
        entity_id: client.entity_id,
        acs_url: client.acs_url
      )

      expect(result).to eq(client)
    end

    it "does not resolve a client from another organization" do
      expect {
        use_case.call(
          organization_id: create(:organization).id,
          entity_id: client.entity_id,
          acs_url: client.acs_url
        )
      }.to raise_error(Errors::ClientApplicationNotFound)
    end

    it "rejects a mismatched ACS URL" do
      expect {
        use_case.call(
          organization_id: organization.id,
          entity_id: client.entity_id,
          acs_url: "https://evil.example.test/callback"
        )
      }.to raise_error(Errors::InvalidAcsUrl)
    end
  end
end
