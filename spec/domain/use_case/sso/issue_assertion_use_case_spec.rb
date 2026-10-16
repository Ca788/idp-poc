# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Sso::IssueAssertionUseCase do
  subject(:use_case) { described_class.new }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:client) { create(:client_application, organization: organization) }

  describe "#call" do
    it "builds a protocol-agnostic identity assertion" do
      assertion = use_case.call(
        organization_id: organization.id,
        user_id: user.id,
        client_application_id: client.id
      )

      expect(assertion.subject).to eq(user.id)
      expect(assertion.email).to eq(user.email)
      expect(assertion.client_application_id).to eq(client.id)
      expect(assertion.organization_id).to eq(organization.id)
    end

    it "does not issue an assertion for a client in another organization" do
      foreign_client = create(:client_application)

      expect {
        use_case.call(
          organization_id: organization.id,
          user_id: user.id,
          client_application_id: foreign_client.id
        )
      }.to raise_error(Errors::ClientApplicationNotFound)
    end

    it "rejects an inactive client" do
      client.update!(active: false)

      expect {
        use_case.call(
          organization_id: organization.id,
          user_id: user.id,
          client_application_id: client.id
        )
      }.to raise_error(Errors::ClientApplicationInactive)
    end
  end
end
