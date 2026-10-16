# frozen_string_literal: true

FactoryBot.define do
  factory :client_application do
    organization
    name { "Portal" }
    protocol { "saml" }
    sequence(:entity_id) { |n| "https://app-#{n}.example.test/metadata" }
    acs_url { "https://app.example.test/sso/callback" }
    active { true }
  end
end
