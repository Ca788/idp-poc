# frozen_string_literal: true

class UseCase::Identity::AuthenticateUserUseCase
  SESSION_TTL = 12.hours

  def initialize(user_repo: User, session_repo: IdentitySession)
    @user_repo = user_repo
    @session_repo = session_repo
  end

  # @param [String] organization_id
  # @param [String] email
  # @param [String] password
  # @return [Models::AuthSession]
  def call(organization_id:, email:, password:)
    user = @user_repo.for_organization(organization_id).find_by(email: email.to_s.strip.downcase)
    raise Errors::InvalidCredentials unless user&.authenticate(password)
    raise Errors::UserInactive unless user.active?

    token = SecureRandom.urlsafe_base64(32)
    expires_at = SESSION_TTL.from_now

    @session_repo.create!(
      organization_id: organization_id,
      user: user,
      token_digest: @session_repo.digest(token),
      expires_at: expires_at
    )

    Models::AuthSession.new(user: user, token: token, expires_at: expires_at)
  end
end
