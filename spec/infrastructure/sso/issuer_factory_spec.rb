# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sso::IssuerFactory do
  describe ".build" do
    it "returns the SAML issuer" do
      expect(described_class.build(:saml)).to be_a(Sso::Saml::Issuer)
    end

    it "returns the OIDC issuer" do
      expect(described_class.build(:oidc)).to be_a(Sso::Oidc::Issuer)
    end

    it "rejects an unknown protocol" do
      expect { described_class.build(:ldap) }.to raise_error(Errors::UnsupportedProtocol)
    end
  end
end
