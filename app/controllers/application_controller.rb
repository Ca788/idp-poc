# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from Errors::OrganizationNotFound, with: :render_not_found
  rescue_from Errors::ClientApplicationNotFound, with: :render_not_found
  rescue_from Errors::InvalidCredentials, with: :render_unauthorized
  rescue_from Errors::UserInactive, with: :render_forbidden
  rescue_from Errors::LoginRateLimited, with: :render_too_many_requests
  rescue_from Errors::ClientApplicationInactive, with: :render_forbidden
  rescue_from Errors::UnsupportedProtocol, with: :render_unprocessable
  rescue_from Errors::CrossOrganizationAccess, with: :render_forbidden
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_error

  private

  def current_organization
    @current_organization ||= begin
      organization_id = request.headers["X-Organization-Id"]
      organization = Organization.find_by(id: organization_id)
      raise Errors::OrganizationNotFound unless organization

      organization
    end
  end

  def render_not_found(error)
    render json: { error: error.class.name.demodulize, message: error.message.presence || "Not found" }, status: :not_found
  end

  def render_unauthorized(error)
    render json: { error: error.class.name.demodulize, message: error.message.presence || "Invalid credentials" }, status: :unauthorized
  end

  def render_forbidden(error)
    render json: { error: error.class.name.demodulize, message: error.message.presence || "Forbidden" }, status: :forbidden
  end

  def render_unprocessable(error)
    render json: { error: error.class.name.demodulize, message: error.message }, status: :unprocessable_entity
  end

  def render_validation_error(error)
    render json: { error: "ValidationError", message: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def render_too_many_requests(_error)
    render json: { error: "TooManyRequests", message: "Too many attempts" }, status: :too_many_requests
  end
end
