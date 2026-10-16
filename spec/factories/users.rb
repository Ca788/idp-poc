# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    organization
    sequence(:email) { |n| "user#{n}@acme.test" }
    first_name { "Ada" }
    last_name { "Lovelace" }
    password { "changeme123" }
    active { true }
  end
end
