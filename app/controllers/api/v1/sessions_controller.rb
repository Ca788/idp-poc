# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ApplicationController
      include IdentitySessionLookup
      include LoginRateLimit

      def create
        enforce_login_rate_limit!

        auth = UseCase::Identity::AuthenticateUserUseCase.new.call(
          organization_id: current_organization.id,
          email: params.require(:email),
          password: params.require(:password)
        )
        rotate_identity_session!(auth.token)
        clear_login_rate_limit

        render json: {
          data: {
            token: auth.token,
            expires_at: auth.expires_at,
            user: {
              id: auth.user.id,
              email: auth.user.email,
              first_name: auth.user.first_name,
              last_name: auth.user.last_name
            }
          }
        }, status: :created
      rescue Errors::InvalidCredentials, Errors::UserInactive
        record_login_failure
        raise
      end
    end
  end
end
