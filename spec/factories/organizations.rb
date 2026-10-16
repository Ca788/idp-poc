# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name { "Acme" }
    sequence(:slug) { |n| "acme-#{n}" }
  end
end
