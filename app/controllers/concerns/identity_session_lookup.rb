# frozen_string_literal: true

module IdentitySessionLookup
  extend ActiveSupport::Concern

  SSO_SESSION_KEYS = %i[saml_request relay_state sso_return_path saml_signature saml_sig_alg].freeze

  private

  def identity_token
    session[:identity_token]
  end

  def store_identity_token(token)
    session[:identity_token] = token
  end

  def preserve_sso_session
    SSO_SESSION_KEYS.index_with { |key| session[key] }
  end

  def restore_sso_session(pending)
    pending.each { |key, value| session[key] = value if value.present? }
  end

  def rotate_identity_session!(token)
    pending = preserve_sso_session
    request.reset_session
    restore_sso_session(pending)
    store_identity_token(token)
    session[:sso_reauth] = true if pending[:saml_request].present?
  end

  def current_identity_session
    return @current_identity_session if defined?(@current_identity_session)

    @current_identity_session =
      if identity_token.present?
        IdentitySession.active.find_by(token_digest: IdentitySession.digest(identity_token))
      end
  end

  def current_user
    current_identity_session&.user
  end
end
