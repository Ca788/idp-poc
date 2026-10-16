# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client applications API" do
  let(:organization) { create(:organization) }
  let(:headers) { { "X-Organization-Id" => organization.id } }

  describe "GET /api/v1/client_applications" do
    before do
      create(:client_application, organization: organization, name: "Alpha")
      create(:client_application, name: "Foreign")
    end

    it "lists org-scoped clients with pagination" do
      get "/api/v1/client_applications", params: { fields: "id,name", per_page: 10 }, headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"].length).to eq(1)
      expect(body["data"].first.keys).to contain_exactly("id", "name")
      expect(body.dig("meta", "total")).to eq(1)
    end
  end

  describe "POST /api/v1/client_applications" do
    it "registers a client in the organization" do
      post "/api/v1/client_applications",
           params: {
             name: "Portal",
             protocol: "saml",
             entity_id: "https://portal.example.test/metadata",
             acs_url: "https://portal.example.test/sso/callback"
           },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "organization_id")).to eq(organization.id)
    end
  end
end
