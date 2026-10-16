# frozen_string_literal: true

module Web
  class BaseController < ActionController::Base
    include IdentitySessionLookup

    layout "web"
    helper_method :current_user

    rescue_from Errors::InvalidCredentials, with: :render_login_error
    rescue_from Errors::UserInactive, with: :render_login_error
    rescue_from Errors::OrganizationNotFound, with: :render_login_error
    rescue_from Errors::LoginRateLimited, with: :render_login_rate_limited
    rescue_from Errors::InvalidSamlRequest, with: :render_saml_error
    rescue_from Errors::ClientApplicationNotFound, with: :render_saml_error
    rescue_from Errors::ClientApplicationInactive, with: :render_saml_error
    rescue_from Errors::InvalidAcsUrl, with: :render_saml_error
    rescue_from Errors::MissingSpCertificate, with: :render_saml_error
    rescue_from Errors::ExpiredSpCertificate, with: :render_saml_error
    rescue_from Errors::UnsupportedProtocol, with: :render_saml_error

    private

    def render_login_error(error)
      @error = error.message.presence || "Não foi possível entrar"
      @organization_slug = params[:organization_slug]
      @email = params[:email]
      render "web/sessions/new", status: :unprocessable_entity
    end

    def render_login_rate_limited(_error)
      @error = "Muitas tentativas. Tente novamente em alguns minutos."
      @organization_slug = params[:organization_slug]
      @email = params[:email]
      render "web/sessions/new", status: :too_many_requests
    end

    def render_saml_error(error)
      Rails.logger.info({ event: "sso.error", error: error.class.name }.to_json)
      render plain: "InvalidSsoRequest", status: :bad_request
    end
  end
end
