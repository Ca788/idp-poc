# frozen_string_literal: true

module Sso
  module Saml
    ParsedRequest = Struct.new(
      :entity_id,
      :acs_url,
      :request_id,
      :destination,
      :issue_instant,
      :force_authn,
      :is_passive,
      keyword_init: true
    )
  end
end
