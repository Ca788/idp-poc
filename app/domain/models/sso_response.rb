# frozen_string_literal: true

module Models
  SsoResponse = Struct.new(
    :payload,
    :acs_url,
    :relay_state,
    :protocol,
    keyword_init: true
  )
end
