# frozen_string_literal: true

module Web
  class SessionsController < BaseController
    include LoginRateLimit

    def new
    end

    def create
      enforce_login_rate_limit!

      organization = Organization.find_by(slug: params.require(:organization_slug).to_s.strip)
      raise Errors::OrganizationNotFound unless organization

      auth = UseCase::Identity::AuthenticateUserUseCase.new.call(
        organization_id: organization.id,
        email: params.require(:email),
        password: params.require(:password)
      )
      rotate_identity_session!(auth.token)
      clear_login_rate_limit

      return_path = session.delete(:sso_return_path)
      if return_path.present?
        redirect_to return_path
      else
        render plain: "Autenticado", status: :ok
      end
    rescue Errors::InvalidCredentials, Errors::UserInactive, Errors::OrganizationNotFound
      record_login_failure
      raise
    end
  end
end
