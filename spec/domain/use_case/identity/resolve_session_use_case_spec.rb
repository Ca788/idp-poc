# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Identity::ResolveSessionUseCase do
  subject(:use_case) { described_class.new }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, password: "secret123") }

  describe "#call" do
    it "resolves an active session by token" do
      auth = UseCase::Identity::AuthenticateUserUseCase.new.call(
        organization_id: organization.id,
        email: user.email,
        password: "secret123"
      )

      record = use_case.call(token: auth.token)

      expect(record.user_id).to eq(user.id)
      expect(record.organization_id).to eq(organization.id)
    end

    it "rejects a missing token" do
      expect { use_case.call(token: nil) }.to raise_error(Errors::SsoSessionRequired)
    end

    it "rejects an unknown token" do
      expect { use_case.call(token: "nope") }.to raise_error(Errors::SsoSessionRequired)
    end
  end
end
