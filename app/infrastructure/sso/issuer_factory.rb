# frozen_string_literal: true

module Sso
  class IssuerFactory
    def self.build(protocol)
      case protocol.to_sym
      when :saml
        Sso::Saml::Issuer.new
      when :oidc
        Sso::Oidc::Issuer.new
      else
        raise Errors::UnsupportedProtocol, protocol.to_s
      end
    end
  end
end
