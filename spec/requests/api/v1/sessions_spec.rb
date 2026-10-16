# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/login" do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, organization: organization, password: "secret123") }

  it "authenticates and returns a session token" do
    post "/api/v1/login",
         params: { email: user.email, password: "secret123" },
         headers: { "X-Organization-Id" => organization.id }

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body.dig("data", "token")).to be_present
    expect(body.dig("data", "user", "email")).to eq(user.email)
  end

  it "returns not found without an organization" do
    post "/api/v1/login", params: { email: user.email, password: "secret123" }

    expect(response).to have_http_status(:not_found)
  end

  it "rate limits repeated failed logins" do
    10.times do
      post "/api/v1/login",
           params: { email: user.email, password: "wrong" },
           headers: { "X-Organization-Id" => organization.id }
      expect(response).to have_http_status(:unauthorized)
    end

    post "/api/v1/login",
         params: { email: user.email, password: "wrong" },
         headers: { "X-Organization-Id" => organization.id }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["error"]).to eq("TooManyRequests")
  end
end
