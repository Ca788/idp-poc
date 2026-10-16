# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Identity::AuthenticateUserUseCase do
  subject(:use_case) { described_class.new }

  let(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization, password: "secret123") }

  describe "#call" do
    it "returns a session token for valid credentials" do
      result = use_case.call(
        organization_id: organization.id,
        email: user.email,
        password: "secret123"
      )

      expect(result.user).to eq(user)
      expect(result.token).to be_present
      expect(result.expires_at).to be > Time.current
      expect(IdentitySession.for_organization(organization.id).count).to eq(1)
    end

    it "does not leak users from another organization" do
      other_org = create(:organization)

      expect {
        use_case.call(
          organization_id: other_org.id,
          email: user.email,
          password: "secret123"
        )
      }.to raise_error(Errors::InvalidCredentials)
    end

    it "rejects a wrong password" do
      expect {
        use_case.call(
          organization_id: organization.id,
          email: user.email,
          password: "wrong"
        )
      }.to raise_error(Errors::InvalidCredentials)
    end

    it "rejects an inactive user" do
      user.update!(active: false)

      expect {
        use_case.call(
          organization_id: organization.id,
          email: user.email,
          password: "secret123"
        )
      }.to raise_error(Errors::UserInactive)
    end
  end
end
