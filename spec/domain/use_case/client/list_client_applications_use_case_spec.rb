# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCase::Client::ListClientApplicationsUseCase do
  subject(:use_case) { described_class.new }

  let(:organization) { create(:organization) }
  let(:other_org) { create(:organization) }

  before do
    create(:client_application, organization: organization, name: "Alpha")
    create(:client_application, organization: organization, name: "Beta")
    create(:client_application, organization: other_org, name: "Other")
  end

  describe "#call" do
    it "lists only clients of the organization" do
      result = use_case.call(organization_id: organization.id)

      expect(result.map(&:name)).to eq(%w[Alpha Beta])
    end

    it "selects only requested fields" do
      result = use_case.call(organization_id: organization.id, fields: %w[id name])
      row = result.first.attributes

      expect(row.keys).to contain_exactly("id", "name")
    end
  end
end
