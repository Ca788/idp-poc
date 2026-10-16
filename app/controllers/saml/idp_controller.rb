# frozen_string_literal: true

module Saml
  class IdpController < Web::BaseController
    skip_forgery_protection only: :auth

    RELAY_STATE_MAX_BYTES = 2048

    def metadata
      render xml: SamlIdp.metadata.signed
    end

    def auth
      raw_request = params[:SAMLRequest].presence || session[:saml_request]
      raise Errors::InvalidSamlRequest if raw_request.blank?

      parsed = Sso::Saml::RequestParser.new.parse(raw_request)
      relay_state = params[:RelayState].presence || session[:relay_state]
      raise Errors::InvalidSamlRequest if relay_state.to_s.bytesize > RELAY_STATE_MAX_BYTES

      if needs_login?(parsed)
        raise Errors::InvalidSamlRequest if parsed.is_passive

        store_pending_request(raw_request, relay_state)
        redirect_to login_path and return
      end

      client = UseCase::Sso::FindClientApplicationUseCase.new.call(
        organization_id: current_identity_session.organization_id,
        entity_id: parsed.entity_id,
        acs_url: parsed.acs_url
      )
      raise Errors::UnsupportedProtocol unless client.protocol == "saml"

      verify_signed_request!(raw_request, relay_state, client)
      Sso::Saml::RequestParser.claim_request_id!(parsed.request_id)

      sso = UseCase::Sso::CompleteSsoUseCase.new.call(
        organization_id: current_identity_session.organization_id,
        user_id: current_identity_session.user_id,
        client_application_id: client.id,
        relay_state: relay_state,
        request_id: parsed.request_id
      )

      clear_pending_request
      log_sso_completed(client, parsed)

      response.set_header("Cache-Control", "no-store, no-cache, must-revalidate, private")
      response.set_header("Pragma", "no-cache")
      @acs_url = sso.acs_url
      @saml_response = sso.payload
      @relay_state = sso.relay_state
      render :acs, layout: false
    end

    private

    def needs_login?(parsed)
      return true if current_identity_session.nil?
      return false unless parsed.force_authn

      session[:sso_reauth].blank?
    end

    def store_pending_request(raw_request, relay_state)
      session[:saml_request] = raw_request
      session[:relay_state] = relay_state
      session[:sso_return_path] = saml_auth_path
      session[:saml_signature] = params[:Signature] if params[:Signature].present?
      session[:saml_sig_alg] = params[:SigAlg] if params[:SigAlg].present?
    end

    def clear_pending_request
      session.delete(:saml_request)
      session.delete(:relay_state)
      session.delete(:sso_return_path)
      session.delete(:saml_signature)
      session.delete(:saml_sig_alg)
      session.delete(:sso_reauth)
    end

    def verify_signed_request!(raw_request, relay_state, client)
      signature = params[:Signature].presence || session[:saml_signature]
      return if signature.blank?

      Sso::Saml::RequestParser.new.verify_query_signature!(
        raw_saml_request: raw_request,
        signature: signature,
        sig_algorithm: params[:SigAlg].presence || session[:saml_sig_alg],
        relay_state: params[:RelayState].presence || relay_state,
        certificate: client.sp_certificate
      )
    end

    def log_sso_completed(client, parsed)
      Rails.logger.info({
        event: "sso.completed",
        organization_id: current_identity_session.organization_id,
        user_id: current_identity_session.user_id,
        client_application_id: client.id,
        request_id: parsed.request_id
      }.to_json)
    end
  end
end
