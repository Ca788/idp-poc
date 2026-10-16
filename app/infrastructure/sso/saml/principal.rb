# frozen_string_literal: true

module Sso
  module Saml
    Principal = Struct.new(:id, :email, :first_name, :last_name, keyword_init: true) do
      alias_method :email_address, :email
    end
  end
end
