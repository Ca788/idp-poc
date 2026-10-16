# frozen_string_literal: true

module Models
  AuthSession = Struct.new(
    :user,
    :token,
    :expires_at,
    keyword_init: true
  )
end
