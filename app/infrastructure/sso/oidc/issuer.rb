# frozen_string_literal: true

module Sso
  module Oidc
    class Issuer < Sso::Issuer
      def issue(assertion:, client_application:, request_id: nil)
        raise NotImplementedError, "OIDC issuer is not implemented yet"
      end
    end
  end
end
