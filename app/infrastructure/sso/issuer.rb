# frozen_string_literal: true

module Sso
  class Issuer
    # @param [Models::IdentityAssertion] assertion
    # @param [ClientApplication] client_application
    # @return [String]
    def issue(assertion:, client_application:, request_id: nil)
      raise NotImplementedError, "#{self.class} must implement #issue"
    end
  end
end
